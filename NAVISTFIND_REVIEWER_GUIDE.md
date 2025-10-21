### NavistFind Reviewer Guide

#### Purpose
Concise guide for reviewers to understand the UI/UX, flows, and logic across the mobile app (Flutter), server (Laravel), and AI service (FastAPI with SBERT) for “NavistFind: AR-based Campus Indoor Navigation with Lost and Found System.”

---

### Repositories and Paths
- Mobile app (Flutter): `C:\FINAL CAPSTONE PROJECT\navistfind`
- Server API + Admin (Laravel): `C:\CAPSTONE PROJECT\campus-nav`
- AI service (FastAPI + sentence-transformers): `C:\CAPSTONE PROJECT\campus-nav-ai`

---

### System Overview
- **Mobile App**: Authentication, campus map + AR navigation launcher, lost & found (post, list, detail, comments, AI-based matches), notifications, profile.
- **Server (API + Admin)**: Auth (Sanctum), items CRUD, comments, profile, AI match orchestration; admin/staff dashboards for items/users/categories/notifications.
- **AI Service**: Receives a reference item + candidate items, returns similarity-ranked matches using SBERT embeddings and cosine similarity.

---

### Deployment & Environment (Summary)
- Mobile base URL: set in `lib/core/constants.dart`
- Server env:
  - `AI_SERVICE_URL`, `AI_BASE_URL`, `AI_TOP_K`, `AI_THRESHOLD`
  - DB and Sanctum variables; see server `ENV_SETUP.md`
- AI module: FastAPI (SBERT) reachable at `ai.yourdomain.com`

### Admin Panel (New Sections)
- Matches Queue: `/admin/matches`
  - AI-suggested Found→Lost pairs with scores; filters for days/minScore
- Claims Review: `/admin/claims`
  - Pending/Approved/Rejected tabs
  - Approve/Reject actions (rejection requires reason)
  - Claimant receives in-app notifications on decisions

### API Additions
- Items search with filters: `GET /api/items?type=&category=&query=&dateFrom=&dateTo=&sort=...`
- Recommendations: `GET /api/items/recommended`
- Claims: `POST /api/items/{id}/claim`, `POST /api/items/{id}/approve-claim`, `POST /api/items/{id}/reject-claim`
- Optional matches on create/update: `include_matches=1`
- AI Feedback: `POST /api/ai/feedback` (best-effort logging)

### Mobile App (Flutter) – UI/UX and Logic
- **Entry & Routing**
  - `lib/app.dart` + `lib/core/navigation/app_routes.dart`
  - `checkAuth` route uses secure storage token to send user to:
    - `LoginScreen` if no token
    - `NavigationWrapper` if token exists
- **Navigation (Bottom Tabs)**: `lib/core/navigation/navigation_bar_app.dart`
  - Tabs: Home, Navigate (Map), Post Item, Heads Up (Notifications), Profile
- **Auth**
  - `features/auth/presentation/login_screen.dart`, `register_screen.dart`
  - Riverpod state; on success, token stored via `SecureStorage`; all requests use `Authorization: Bearer <token>`
- **Networking**
  - `lib/core/network/api_client.dart` (Dio), `lib/core/constants.dart` for base URL
  - `lib/core/secure_storage.dart` (FlutterSecureStorage) for token
- **Lost & Found (Student UX)**
  - List: `features/item/presentation/items_screen.dart` → `GET /api/items`
  - Detail: `item_details_screen.dart` → `GET /api/items/{id}`, “View Matches” → `GET /api/items/{id}/matches` → displays `ai_match_card.dart` / `matched_items_modal.dart`
  - Post/Edit: `post-item/presentation/post_item_screen.dart` and `edit_item_screen.dart` → `POST /api/items`, `PUT /api/items/{id}`
  - Comments: `comment_service.dart` → `POST /api/comments`, `GET /api/comments?item_id=...`
- **Map + AR Navigation**
  - Map: `features/map/presentation/campus_map_screen.dart`
    - OSM map with building markers, category filter, debounced search across names/rooms
    - Building catalog is static in-app (academic/admin/recreational/etc.)
    - Dialog actions:
      - “Start AR Navigation” → `ARTransitionScreen`
      - Conditional “AR Navigation” button if Unity app installed
  - AR Transition & Launcher:
    - `ar_transition_screen.dart`: Readiness checks (device/app), guidance tips, launches Unity via intents
    - `ar_navigation_launcher_widget.dart`: Button/FAB/Card variants to launch Unity AR app
    - Launch methods: `external_app_launcher` and `android_intent_plus`; target package `com.navistfind.ARNav` (extras: destination, names, etc.)

Notes
- Known text-encoding artifacts (e.g., “â€¢”, “âœ…”) should be saved as UTF‑8 proper bullets/ticks.
- `constants.dart` has a LAN IP; consider per-env build config.

---

### Server (Laravel) – API, Admin, and Logic
- **Routes**
  - API (`routes/api.php`)
    - Public: `POST /api/register`, `POST /api/login`
    - Protected (Sanctum + `ApiAuthMiddleware`):
      - `GET /api/user`, `POST /api/logout`
      - `GET /api/me`, `GET /api/me/items`
      - Comments: `POST /api/comments`, `GET /api/comments?item_id=...`
      - Items: `GET /api/items`, `POST /api/items`, `GET /api/items/{id}`, `PUT /api/items/{id}`, `DELETE /api/items/{id}`, `GET /api/items/{id}/matches`
  - Web (`routes/web.php`)
    - Role-gated admin/staff: `dashboard`, `campus-map`, `item` (CRUD), `users`, `notifications`, `categories`, `profile`
- **Controllers**
  - API `ItemController`:
    - Filters candidates by opposite type and `unclaimed` status
    - Calls `App\Services\AIService::matchLostAndFound` and returns matched items with scores
- **AI Bridge** (`app/Services/AIService.php`)
  - Config-driven: `services.ai_service.base_url` and `api_key`
  - Endpoints called:
    - `POST /v1/match-items` → returns `{ matched_items: [{ id, score }] }`
    - `POST /v1/match-items/best` → returns `{ highest_best, lower_best }`
- **Middleware**
  - `ApiAuthMiddleware`: standardizes 401/403 JSON messages for mobile client UX

---

### AI Service (FastAPI + SBERT) – Current Expectations
- Repo shows:
  - Dependencies: `fastapi`, `uvicorn`, `pydantic`, `python-dotenv`, `requests`, `sentence-transformers`
  - Start: `uvicorn app.main:app --host 127.0.0.1 --port 8010 --reload`
- Contract expected by Laravel:
  - `POST /v1/match-items`
    - Input: `{ reference_item: {...}, candidate_items: [...] }`
    - Output: `{ matched_items: [{ id, score }, ...] }`
  - `POST /v1/match-items/best`
    - Output: `{ highest_best: {id, score} | null, lower_best: {id, score} | null }`

---

### End-to-End Flows

- **Authentication**
  - Mobile login/register → token stored → all API calls include bearer token → `checkAuth` routes users accordingly

- **Lost & Found**
  - Post lost/found item (mobile) → admin/staff manage in dashboard → user opens item detail → “matches” calls AI via server → results displayed with confidence score and claim/contact options

- **AR Navigation**
  - User selects destination in map → transition screen readiness checks → launch Unity AR app via Android intent → user guided by 3D arrows

---

### Configuration and Environment

- **Mobile**
  - `lib/core/constants.dart` → base API URL (per environment)
  - Permissions: location, camera; Unity AR app must be installed (`com.navistfind.ARNav`)

- **Server**
  - Sanctum for API tokens
  - `config/services.php`:
    - `ai_service.base_url` = e.g., `http://127.0.0.1:8010`
    - `ai_service.api_key` = set in `.env`

- **AI Service**
  - `.env`: `AI_API_KEY`, `PORT=8010`, `MODEL_NAME`, `TOP_K`, `THRESHOLD`
  - Enable CORS for the server host

---

### Reviewer Checklist

- **Mobile UI/UX**
  - Auth screens route correctly with token presence
  - Map search/filter UX responsiveness and correctness
  - AR launcher: proper prompts when Unity app missing vs installed
  - Lost & Found: posting, listing, detail, comments, matches UI

- **API correctness**
  - Auth returns token and protects routes
  - `GET /api/items/{id}/matches` produces meaningful ranked matches
  - Admin routes enforce role middleware

- **AI behavior**
  - Returns stable scores for similar items
  - Threshold/top_k configurable
  - Handles empty candidates / malformed payload gracefully

- **Encoding/Localization**
  - Replace mis-encoded characters (bullets, quotes, ticks)
  - Consistent date/time and category labels

---

### AI Finalization Plan (SBERT-Based)

- **Model**
  - Default: `all-MiniLM-L6-v2` (fast, good quality); optional `all-mpnet-base-v2` (higher quality)
- **Normalization**
  - Build item text from: name, category, description, location, date (as text)
  - Lowercase, strip punctuation/extra whitespace
- **Embeddings & Cache**
  - Precompute embeddings for all items; store in memory with periodic refresh, or persist to disk/DB
- **Matching**
  - On request: embed reference item; cosine similarity vs candidate vectors
  - Return top_k (e.g., 5–10) above threshold (e.g., 0.60)
  - Optional boosts: same category, time/geo proximity if available
  - Optional cross-encoder re-rank for top 5 (toggleable)
- **API**
  - `POST /v1/match-items` → `{ matched_items: [{id, score}] }`
  - `POST /v1/match-items/best` → “top 1” and “runner-up”
  - `GET /health` for readiness
- **Ops**
  - `.env` config, structured errors, CORS
  - Basic metrics (latency, hit rate) for tuning

---

### Known Issues / To Improve

- **Text encoding**: Fix display of bullets/ticks in multiple Flutter screens (save UTF‑8 and replace artifacts)
- **Config management**: Move API base URL and AR package names into per-build environment configs
- **Building data**: Consider backend-managed buildings/rooms if staff should update campus map

---

### Quick References

- Mobile routes: `AppRoutes.checkAuth`, `login`, `register`, `home`
- Item endpoints:
  - `GET /api/items`, `POST /api/items`, `GET /api/items/{id}`, `PUT /api/items/{id}`, `DELETE /api/items/{id}`
  - `GET /api/items/{id}/matches`
- Comments: `POST /api/comments`, `GET /api/comments?item_id=...`
- AI: `POST /v1/match-items`, `POST /v1/match-items/best`
Mobile app (student/staff) – proposed UI structure
Auth
Login, Register
Main shell
Bottom tabs:
Home
Recommended for you (AI-ranked Found items for students; Lost needing review for staff)
Recent items (fallback list)
Navigate
Campus map (search + filter)
Building dialog → AR Transition screen → Launch Unity AR
Lost & Found
Feed with search and filters (type, category, date)
Sort by relevance (AI) or newest
Item detail
Photos, metadata
AI Matches panel (Found items for student’s Lost)
Start claim (student) / Contact admin
Comments
Heads Up (Notifications)
Match alerts, claim status, admin messages
Profile
My posts (Lost for students; Lost/Found for staff)
My claims (status)
Preferences (categories), Logout
Global “Post” (students only create Lost)
Keep as current center tab or change to floating action button (FAB)
3-step wizard: Details → Photos → Preview
After submit: “Possible matches” (AI) → Claim or Dismiss
Search UX (Lost & Found tab)
Keyword + filters (type, category, date range)
Debounced input, paginated results
If weak/no results: show AI Suggestions
Admin web – proposed UI structure
Dashboard
KPIs: new items, pending claims, match rate
Items
List + filters (type, category, date, status)
Create (Lost or Found), Edit, Delete
Item detail: photos, metadata, linked matches
Matches queue
AI-suggested pairs (Found→Lost) with scores
Actions: Approve link / Dismiss / Notify owner
Claims
Pending, Approved, Rejected
Review details, verify, approve/reject with notes
Users
Manage students/staff/admin roles
Categories
Create/Delete categories
Campus map
View/update buildings/rooms (optional future: manage from backend)
Notifications
Configure broadcast/admin messages
Profile/Settings
Admin account, API keys (AI), thresholds (optional)
Flow highlights
Student posts Lost → AI finds matching Found → show on submit + notify later if new matches.
Admin posts Found → AI finds matching Lost → queue + notify owners; admin can link pairs.
Item detail always shows AI Matches (opposite type, unclaimed) with confidence.
Claims: student requests → admin verifies → item status updates, both sides notified.
Minimal changes from current app
Keep existing bottom tabs and AR flow.
Post Item (mobile): remove type picker; always send type=lost.
Lost & Found tab: add top search bar + filters; add “Sort: Relevance/Newest”.
Item detail: add “AI Matches” panel and “Start claim” CTA (students).
Home: add “Recommended for you” section (uses personalized AI endpoint).
Admin web: add “Matches queue” and “Claims” sections.
API/AI tie-in (for the UI)
GET /api/items (feed/search with filters, sorting)
GET /api/items/{id} (detail)
GET /api/items/{id}/matches (AI matches panel)
GET /api/items/recommended (Home recommendations)
POST /api/ai/feedback (thumbs up/down on matches, optional)
Claims endpoints (create/update) for the claim flow
AI service keeps SBERT similarity with top_k and threshold; batch endpoints for admin queue (optional)