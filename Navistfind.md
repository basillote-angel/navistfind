### UI structure (mobile)
- Home
  - Recommended for you: AI-ranked found items if you posted “lost”; AI-ranked lost items if you posted “found”.
  - Recent items: chronological fallback.
- Navigate
  - Campus map → building dialog → AR transition (unchanged).
- Lost & Found
  - Items feed: filters (type, category, date), sort (relevance, newest).
  - Post item: 3-step wizard (details → photos → confirm); show “Possible matches” after submit.
  - Item detail: gallery, metadata, “AI Matches” panel with scores, “Start claim” CTA, comments.
- Notifications
  - Match alerts, claim decisions, admin messages.
- Profile
  - My posts (lost/found), claims, preferences (categories), logout.

### UX flows
- Post lost item
  - Enter name, category, description, location, date, photos → submit → immediate AI match preview → “Start claim” or “Dismiss”.
- Post found item (admin/staff or user)
  - Same capture; show AI suggestions to link a matching lost item; mark as “linked”.
- Claim
  - From item detail/match card → confirm → chat/admin verification → item status updates to “claimed” on approval.
- Discovery
  - Home shows AI-ranked list tailored by your posts/history; item detail shows “Similar items”.

### Backend logic (where AI fits)
- Matching (existing)
  - Keep `GET /api/items/{id}/matches` powered by FastAPI SBERT + cosine similarity; enforce top_k and threshold.
- Personalization (new)
  - Endpoint: `GET /api/items/recommended` returns items ranked for the current user:
    - If user has active lost posts → recommend candidate found items.
    - If user posted found → recommend candidate lost items.
- Feedback loop (new)
  - Endpoint: `POST /api/ai/feedback` with `{reference_item_id, matched_item_id, label: positive|negative}` to store signals for re‑ranking/tuning.
- Background jobs
  - On item create/update: queue embedding computation (AI service) and cache result.
  - Periodic job: re-scan active items to push match notifications.

### Data model additions
- `item_embeddings` (item_id, vector, model, last_embedded_at)
- `match_events` (reference_item_id, candidate_item_id, score, created_at)
- `match_feedback` (reference_item_id, candidate_item_id, user_id, label, created_at)
- `claims` (item_id, claimant_user_id, status: pending|approved|rejected, notes)

### Scoring strategy
- Base: SBERT cosine similarity on normalized text: name + category + description + location + date (string).
- Weights (optional, additive):
  - Category match: +w1
  - Date proximity (days apart): +w2 decay
  - Location proximity (if coordinates present): +w3 decay
  - Feedback: positive boosts, negative penalizes pairs over time.
- Thresholds
  - Hide scores < 0.55 (adjustable in .env).
  - Show top 5–10.

### API surface (concise)
- GET /api/items/{id}/matches → existing (keep)
- GET /api/items/recommended → new (personalized list)
- POST /api/ai/feedback → new (store label)
- Optional: GET /api/items/matches/batch?ids=… for admin queue efficiency

### Admin dashboard additions
- Matches queue
  - Table of suggested pairs with scores; approve/link or dismiss.
- Claims review
  - Approve/reject with notes; auto-notify users.
- Analytics
  - Match rate, median score, false-positive feedback, time‑to‑claim.

### Notifications
- On new high-confidence match (score ≥ threshold) → push notification to owner/finder.
- On claim status change → notify claimant.

### Performance & UX safeguards
- Pagination + infinite scroll on feeds.
- Lazy-load images; show skeletons.
- Explainability: show “Why recommended” chips (category/date/location).
- Safety: rate-limit feedback; sanitize inputs.

### What to implement next (small, high-impact)
- Mobile
  - Home “Recommended for you” section (consumes `GET /api/items/recommended`).
  - Item detail “AI Matches” panel with confidence badge and “This isn’t a match” feedback.
- Server
  - `GET /api/items/recommended` (derive reference set from user’s active posts; call AI in batch).
  - `POST /api/ai/feedback` (store labels).
- AI service
  - Batch scoring endpoint (accept multiple reference items).
  - Optional: apply simple re‑rank with feedback weights.

