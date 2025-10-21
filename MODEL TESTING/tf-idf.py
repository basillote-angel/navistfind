#!/usr/bin/env python3
"""
TF-IDF retrieval baseline for Lost & Found matching.

- Loads: Excel dataset (items).
- Preprocesses: text per item (name + description + category).
- Builds: TF-IDF vectorizer (unigram+bigram).
- Retrieves: for each LOST query, ranks FOUND candidates by cosine similarity.
- Evaluates (if labels present): Recall@K, MRR, nDCG@K.
- Saves: per-pair scores and summary metrics.

Expected columns (sheet can be any; default 'items'):
- itemId (int/str)
- type ('lost'|'found')
- name (str)
- description (str)
- category (str)
- location (str, optional)
- lostFoundDate (YYYY-MM-DD, optional)
- createdAt (ISO, optional)
Optional labels (any one works):
- matchGroupId (same value for true lost↔found pairs)
- trueMatchId (id of the counterpart item)

Dependencies:
  pip install pandas numpy scikit-learn openpyxl
"""

import argparse
import os
import json
from datetime import datetime
from typing import List, Dict, Optional, Tuple

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import linear_kernel


def loadDataset(filePath: str, sheetName: Optional[str]) -> pd.DataFrame:
    lower = filePath.lower()
    # CSV support
    if lower.endswith(".csv"):
        return pd.read_csv(filePath, encoding="utf-8")

    readKw = {"engine": "openpyxl"} if lower.endswith((".xlsx", ".xlsm")) else {}
    if sheetName:
        try:
            df = pd.read_excel(filePath, sheet_name=sheetName, **readKw)
            return df
        except ValueError as e:
            # Fallback: if specified sheet is missing, load the first sheet
            msg = str(e)
            if "Worksheet named" in msg and "not found" in msg:
                try:
                    xls = pd.ExcelFile(filePath, engine=readKw.get("engine")) if readKw else pd.ExcelFile(filePath)
                    if not xls.sheet_names:
                        raise
                    firstSheet = xls.sheet_names[0]
                    print(f"Warning: worksheet '{sheetName}' not found. Falling back to first sheet '{firstSheet}'.")
                    return pd.read_excel(filePath, sheet_name=firstSheet, **readKw)
                except Exception:
                    # Re-raise original if fallback also fails
                    raise
            else:
                raise
    else:
        df = pd.read_excel(filePath, **readKw)
        return df


def isPairwiseSchema(df: pd.DataFrame) -> bool:
    required = {"pair_id", "lost_description", "found_description", "category", "date_lost", "date_found", "label"}
    return required.issubset(set(df.columns))


def transformPairwiseToRetrieval(dfPairs: pd.DataFrame) -> pd.DataFrame:
    # Normalize and parse dates
    dfPairs = dfPairs.copy()
    dfPairs["lost_description"] = dfPairs["lost_description"].astype(str)
    dfPairs["found_description"] = dfPairs["found_description"].astype(str)
    dfPairs["category"] = dfPairs["category"].astype(str)
    dfPairs["date_lost"] = pd.to_datetime(dfPairs["date_lost"], errors="coerce")
    dfPairs["date_found"] = pd.to_datetime(dfPairs["date_found"], errors="coerce")

    # Create FOUND catalog (unique by description+category+date_found)
    found = (
        dfPairs[["found_description", "category", "date_found"]]
        .drop_duplicates()
        .rename(columns={"found_description": "description", "date_found": "lostFoundDate"})
    )
    found["type"] = "found"
    found["name"] = ""
    found["itemId"] = [f"F{i+1}" for i in range(len(found))]

    # Map found description to itemId
    foundIdByDesc = pd.Series(found["itemId"].values, index=found["description"]).to_dict()

    # Create LOST catalog (unique by description+category+date_lost)
    lost = (
        dfPairs[["lost_description", "category", "date_lost"]]
        .drop_duplicates()
        .rename(columns={"lost_description": "description", "date_lost": "lostFoundDate"})
    )
    lost["type"] = "lost"
    lost["name"] = ""
    lost["itemId"] = [f"L{i+1}" for i in range(len(lost))]

    # Build positive mapping from lost_description -> found_description where label==1
    posMap = (
        dfPairs[dfPairs["label"].astype(int) == 1]
        .drop_duplicates(subset=["lost_description"])  # assume one positive per lost query in this dataset
        .set_index("lost_description")["found_description"].to_dict()
    )

    def mapTrueMatchId(lostDesc: str) -> Optional[str]:
        posFoundDesc = posMap.get(lostDesc)
        if posFoundDesc is None:
            return np.nan
        return foundIdByDesc.get(posFoundDesc, np.nan)

    # Attach trueMatchId for evaluation
    lost["trueMatchId"] = lost["description"].map(mapTrueMatchId)

    # Combine
    combined = pd.concat([lost, found], ignore_index=True, sort=False)
    cols = ["itemId", "type", "name", "description", "category", "lostFoundDate", "trueMatchId"]
    for c in cols:
        if c not in combined.columns:
            combined[c] = np.nan
    return combined[cols]


def validateColumns(df: pd.DataFrame) -> None:
    required = {"itemId", "type", "name", "description", "category"}
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    # Normalize types
    df["type"] = df["type"].astype(str).str.lower().str.strip()
    allowedTypes = {"lost", "found"}
    badTypes = df.loc[~df["type"].isin(allowedTypes), "type"].unique().tolist()
    if badTypes:
        raise ValueError(f"Invalid values in 'type': {badTypes} (expected 'lost' or 'found')")


def safeString(x) -> str:
    if pd.isna(x):
        return ""
    return str(x)


def composeTextRow(row: pd.Series) -> str:
    name = safeString(row.get("name", ""))
    description = safeString(row.get("description", ""))
    category = safeString(row.get("category", ""))
    return f"{name}. {description}. Category: {category}"


def preprocessData(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["text"] = df.apply(composeTextRow, axis=1).str.lower()
    # Dates optional
    for col in ["lostFoundDate", "createdAt"]:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce", utc=False)
    return df


def buildTfidf(texts: List[str],
               ngramRange: Tuple[int, int] = (1, 2),
               minDf: int = 2,
               sublinearTf: bool = True) -> Tuple[TfidfVectorizer, "scipy.sparse.csr_matrix"]:
    vectorizer = TfidfVectorizer(
        ngram_range=ngramRange,
        min_df=minDf,
        lowercase=True,
        sublinear_tf=sublinearTf,
        norm="l2"
    )
    matrix = vectorizer.fit_transform(texts)
    return vectorizer, matrix


def pickCandidates(df: pd.DataFrame,
                   queryRow: pd.Series,
                   daysWindow: Optional[int]) -> pd.Index:
    # Base: all FOUND items
    foundMask = df["type"] == "found"
    idx = df.index[foundMask]

    if daysWindow is None:
        return idx

    # Optional time window filtering using lostFoundDate if available
    if ("lostFoundDate" in df.columns) and pd.notna(queryRow.get("lostFoundDate", pd.NaT)):
        qDate = queryRow["lostFoundDate"]
        if pd.isna(qDate):
            return idx
        if not np.issubdtype(df["lostFoundDate"].dtype, np.datetime64):
            return idx
        delta = (df.loc[idx, "lostFoundDate"] - qDate).abs()
        keep = delta.dt.days <= daysWindow
        return idx[keep]
    return idx


def getPositiveIdsForQuery(queryRow: pd.Series, df: pd.DataFrame) -> List[str]:
    # Support either matchGroupId or trueMatchId
    positives: List[str] = []
    if "trueMatchId" in queryRow and pd.notna(queryRow["trueMatchId"]):
        positives = [str(queryRow["trueMatchId"])]
    elif "matchGroupId" in queryRow and pd.notna(queryRow["matchGroupId"]):
        groupId = queryRow["matchGroupId"]
        # All items (opposite type) sharing this group are positives
        oppType = "found" if queryRow["type"] == "lost" else "lost"
        positives = df.loc[(df["matchGroupId"] == groupId) & (df["type"] == oppType), "itemId"].astype(str).tolist()
    return [str(p) for p in positives]


def computeRankMetrics(perQueryRanks: List[int]) -> Dict[str, float]:
    # perQueryRanks: list of 1-based best ranks for queries that have at least one positive in candidate set
    if len(perQueryRanks) == 0:
        return {"mrr": float("nan"), "recall@1": float("nan"), "recall@3": float("nan"), "recall@5": float("nan"), "recall@10": float("nan")}
    ranks = np.array(perQueryRanks)
    mrr = np.mean(1.0 / ranks)
    def recallAtK(k: int) -> float:
        return float(np.mean(ranks <= k))
    return {
        "mrr": float(mrr),
        "recall@1": recallAtK(1),
        "recall@3": recallAtK(3),
        "recall@5": recallAtK(5),
        "recall@10": recallAtK(10),
    }


def computeNdcgAtK(gains: List[List[int]], k: int) -> float:
    # gains: per-query list of binary relevance in ranked order (1/0)
    def dcg(xs):
        xs = np.array(xs[:k], dtype=float)
        if xs.size == 0:
            return 0.0
        discounts = 1.0 / np.log2(np.arange(2, xs.size + 2))
        return float(np.sum(xs * discounts))
    scores = []
    for g in gains:
        ideal = sorted(g, reverse=True)
        idcg = dcg(ideal)
        if idcg == 0:
            continue
        scores.append(dcg(g) / idcg)
    if len(scores) == 0:
        return float("nan")
    return float(np.mean(scores))


def evaluateRetrieval(df: pd.DataFrame,
                      tfidfMatrix: "scipy.sparse.csr_matrix",
                      vectorizer: TfidfVectorizer,
                      outputDir: str,
                      daysWindow: Optional[int],
                      topKToSave: int = 50) -> Dict[str, float]:
    # Split query/candidate indices
    lostIdx = df.index[df["type"] == "lost"]
    itemIdSeries = df["itemId"].astype(str)

    # Prepare containers
    resultRows = []
    bestRanks: List[int] = []
    ndcgGains: List[List[int]] = []

    # For performance: pre-map itemId -> row index
    idToRow: Dict[str, int] = {str(i): int(r) for r, i in enumerate(itemIdSeries.tolist())}

    # Iterate queries
    for qi, rowIdx in enumerate(lostIdx.tolist(), start=1):
        queryRow = df.loc[rowIdx]
        candidateIdx = pickCandidates(df, queryRow, daysWindow)

        if len(candidateIdx) == 0:
            continue

        # Vectorize query text (use transform to reuse vocabulary)
        queryVec = vectorizer.transform([queryRow["text"]])
        candidateMat = tfidfMatrix[candidateIdx, :]

        # Cosine similarity for sparse TF-IDF via linear_kernel
        sims = linear_kernel(queryVec, candidateMat).ravel()  # shape: (numCandidates,)

        # Build DataFrame of candidates with scores
        sub = pd.DataFrame({
            "candidateRow": candidateIdx,
            "candidateId": itemIdSeries.loc[candidateIdx].values,
            "score": sims
        })
        sub.sort_values("score", ascending=False, inplace=True, kind="mergesort")
        sub["rank"] = np.arange(1, len(sub) + 1)

        # Label positives if ground-truth available
        positives = getPositiveIdsForQuery(queryRow, df)
        if positives:
            sub["isMatch"] = sub["candidateId"].astype(str).isin(positives).astype(int)
            posRows = sub[sub["isMatch"] == 1]
            if len(posRows) > 0:
                bestRank = int(posRows["rank"].min())
                bestRanks.append(bestRank)

            # For nDCG gains at K
            gains = sub["isMatch"].astype(int).tolist()
            ndcgGains.append(gains)
        else:
            sub["isMatch"] = 0

        # Keep only topKToSave for output files (optional)
        subOut = sub.head(topKToSave).copy()
        subOut.insert(0, "queryId", str(queryRow["itemId"]))
        resultRows.append(subOut[["queryId", "candidateId", "score", "rank", "isMatch"]])

        if qi % 50 == 0:
            print(f"[TFIDF] Processed {qi}/{len(lostIdx)} queries...")

    # Concatenate and save results
    if resultRows:
        allResults = pd.concat(resultRows, ignore_index=True)
    else:
        allResults = pd.DataFrame(columns=["queryId", "candidateId", "score", "rank", "isMatch"])

    os.makedirs(outputDir, exist_ok=True)
    scoresPath = os.path.join(outputDir, "tfidf_results.csv")
    allResults.to_csv(scoresPath, index=False, encoding="utf-8")
    print(f"Saved scores to: {scoresPath}")

    # Metrics
    metrics: Dict[str, float] = computeRankMetrics(bestRanks)
    metrics["ndcg@10"] = computeNdcgAtK([g for g in ndcgGains], k=10)

    metricsPath = os.path.join(outputDir, "tfidf_metrics_summary.json")
    with open(metricsPath, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2)
    print(f"Saved metrics to: {metricsPath}")
    print("Metrics:", metrics)

    return metrics


def main():
    parser = argparse.ArgumentParser(description="TF-IDF retrieval baseline for Lost & Found.")
    parser.add_argument("--data_path", type=str, default=r"C:\\CAPSTONE PROJECT\\MODEL TESTING\\lostfound_dataset.csv",
                        help="Path to Excel/CSV dataset (default: local CSV path).")
    parser.add_argument("--sheet", type=str, default="items", help="Excel sheet name (ignored for CSV).")
    parser.add_argument("--output_dir", type=str, default=r"C:\\CAPSTONE PROJECT\\MODEL TESTING\\outputs",
                        help="Directory to write outputs.")
    parser.add_argument("--days_window", type=int, default=14,
                        help="Optional time window in days to filter candidates (None to disable).")
    parser.add_argument("--min_df", type=int, default=2, help="TF-IDF min_df.")
    parser.add_argument("--use_bigrams", action="store_true", help="Enable bigrams in TF-IDF (default: on).")
    parser.add_argument("--no_bigrams", action="store_true", help="Disable bigrams in TF-IDF.")
    args = parser.parse_args()

    if args.no_bigrams:
        ngramRange = (1, 1)
    else:
        ngramRange = (1, 2)

    # Load
    print(f"Loading dataset from: {args.data_path}")
    dfRaw = loadDataset(args.data_path, args.sheet)
    if isPairwiseSchema(dfRaw):
        print("Detected pairwise CSV schema; transforming to retrieval format...")
        df = transformPairwiseToRetrieval(dfRaw)
    else:
        df = dfRaw
    validateColumns(df)
    df = preprocessData(df)

    # Build TF-IDF over all items
    print("Fitting TF-IDF vectorizer...")
    vectorizer, tfidfMatrix = buildTfidf(
        texts=df["text"].tolist(),
        ngramRange=ngramRange,
        minDf=args.min_df,
        sublinearTf=True
    )

    # Evaluate (LOST queries vs FOUND candidates)
    metrics = evaluateRetrieval(
        df=df,
        tfidfMatrix=tfidfMatrix,
        vectorizer=vectorizer,
        outputDir=args.output_dir,
        daysWindow=args.days_window if args.days_window is not None else None,
        topKToSave=50
    )

    print("\nDone. Summary:")
    for k, v in metrics.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()


