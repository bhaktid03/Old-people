## Backend Architecture & API Plan (Do Not Implement Yet)

This document captures the folder structure, data models, API surface, and implementation plan for the backend powering the app screens shown (News feed, Article detail, Share Vichaar: audio/text/video, Community Wall with Trending/Recent, Respect reactions, Comments, Profile with My Thoughts and Respect Points).

Stack baseline from existing `package.json`:
- Runtime: Node.js (ESM) + TypeScript
- Framework: Express
- Database: MongoDB (native driver)
- Logging: pino (+ pino-pretty for dev)

All endpoints below are namespaced under `/api/v1`.

---

### 1) Proposed Folder Structure

```
backend/
  src/
    app.ts                # express app setup (middleware, routes mounting)
    server.ts             # server bootstrap (env, db, listen)
    config/
      env.ts              # env loading/validation
      mongo.ts            # Mongo client + connection helpers
      storage.ts          # media storage config (S3/Cloudinary) abstraction
      security.ts         # CORS, rate-limit, helmet setup
    core/
      errors/
        http-error.ts     # base HttpError and typed errors
        error-mapper.ts   # error -> response mapping
      logger.ts           # pino logger factory
      pagination.ts       # cursor/offset pagination helpers
      validation.ts       # zod/yup validators (to be chosen) wrappers
      auth.ts             # JWT creation/verification, auth helpers
      roles.ts            # role/permission guards
    features/
      auth/
        auth.routes.ts
        auth.controller.ts
        auth.service.ts
        auth.validators.ts
        auth.types.ts
      users/
        user.routes.ts
        user.controller.ts
        user.service.ts
        user.repo.ts
        user.validators.ts
        user.types.ts
      profiles/
        profile.routes.ts
        profile.controller.ts
        profile.service.ts
        profile.repo.ts
        profile.types.ts
      posts/
        post.routes.ts
        post.controller.ts
        post.service.ts
        post.repo.ts
        post.validators.ts
        post.types.ts
      comments/
        comment.routes.ts
        comment.controller.ts
        comment.service.ts
        comment.repo.ts
        comment.types.ts
      reactions/
        reaction.routes.ts
        reaction.controller.ts
        reaction.service.ts
        reaction.repo.ts
        reaction.types.ts
      points/
        points.routes.ts
        points.controller.ts
        points.service.ts
        points.repo.ts
        points.types.ts
      media/
        media.routes.ts        # presigned URLs, direct upload callbacks
        media.controller.ts
        media.service.ts
        media.storage.ts       # S3/Cloudinary adapter implementation
        media.types.ts
      feeds/
        feed.routes.ts         # news + community timelines
        feed.controller.ts
        feed.service.ts
        feed.repo.ts
        feed.types.ts
      news/
        news.routes.ts         # external news proxy/aggregation
        news.controller.ts
        news.service.ts
        news.providers/
          indian_express.ts    # example provider
          provider.types.ts
      ivr/
        ivr.routes.ts          # webhook endpoints
        ivr.controller.ts
        ivr.service.ts
        ivr.types.ts
      moderation/
        moderation.routes.ts   # reports, takedowns
        moderation.controller.ts
        moderation.service.ts
        moderation.repo.ts
        moderation.types.ts
      notifications/
        notification.routes.ts
        notification.controller.ts
        notification.service.ts
        notification.repo.ts
        notification.types.ts
    middleware/
      auth.middleware.ts
      validation.middleware.ts
      error.middleware.ts
      request-id.middleware.ts
    routes/
      index.ts               # aggregate, mount feature routers
    schemas/
      mongo/
        indexes.ts           # ensureIndexes on startup
    types/
      common.ts
    utils/
      id.ts                 # ULIDs/UUIDs, snowflake helpers
      time.ts
  test/                     # later: unit/integration tests
  BACKEND_PLAN.md           # this document
```

Notes:
- Each feature folder follows routes -> controller -> service -> repo layering.
- `repo.ts` files contain Mongo data access (collections, indexes, queries).
- Media uploads use presigned URLs and a background callback to finalize metadata.
- IVR module supports voice recording via telephony provider webhooks.

---

### 2) Core Domain Models (MongoDB collections)

- users
  - _id, phone, email?, passwordHash?, status, createdAt, updatedAt, lastLoginAt, roles[]
- profiles
  - _id (userId), displayName, avatarUrl, bio, language, respectPoints, counters { posts, comments }
- posts
  - _id, authorId, type: "text" | "media" | "link" (derived by payload)
  - content {
      text?,
      attachments?: Array<{
        mediaId,
        kind: "image" | "video" | "audio" | "file",
        caption?
      }>,
      linkUrl?,
      linkMeta?
    }
  - stats { reactions, comments, shares }
  - visibility: "public" | "private"
  - createdAt, updatedAt
- media
  - _id, kind: "audio" | "video" | "image" | "file",
    storage { provider, key, url, contentType, sizeBytes, durationSec? },
    checksum?,
    filename?,
    ownerId,
    createdAt
- reactions
  - _id, userId, postId, kind: "respect", createdAt (unique on userId+postId+kind)
- comments
  - _id, postId, authorId, text, createdAt, updatedAt
- points_ledger
  - _id, userId, delta, reason: "post" | "reaction_received" | "comment" | "admin_adjustment", createdAt, balanceAfter
- news_articles (optional cache)
  - _id, source, title, url, summary, imageUrl?, publishedAt, checksum
- follows (optional later)
  - followerId, followeeId, createdAt
- reports (moderation)
  - _id, reporterId, entityType: "post" | "comment" | "user", entityId, reason, status, createdAt, resolvedAt?
- notifications
  - _id, userId, type, payload, readAt?, createdAt

Indexes to plan:
- users.phone unique, profiles.userId unique
- posts.authorId, posts.createdAt (compound), posts.stats.reactions (for trending)
- reactions unique (userId+postId+kind)
- comments.postId + createdAt
- points_ledger.userId + createdAt

---

### 3) API Endpoints (spec outline)

Base: `/api/v1`

Authentication
- POST `/auth/register` — body: { phone | email, otp? or password }; returns { user, tokens }
- POST `/auth/login` — body: { phone|email, password|otp }; returns { user, tokens }
- POST `/auth/refresh` — body: { refreshToken } -> { accessToken }
- POST `/auth/logout` — invalidates refresh token

Users & Profiles
- GET `/me` — current user profile (auth)
- PUT `/me` — update profile fields { displayName, bio, language }
- POST `/me/avatar/presign` — get presigned URL for avatar upload
- POST `/me/avatar/complete` — finalize uploaded avatar { key, url }
- GET `/users/:id` — public profile
- GET `/users/:id/points` — { total, recent: [{delta, reason, createdAt}] }

Media
- POST `/media/presign` — body: { kind: audio|video|image|file, contentType } -> { uploadUrl, key, url }
- POST `/media/complete` — body: { key, url, durationSec? } -> { mediaId }

Posts ("Thoughts")
- POST `/posts` — body: {
  type: "text" | "media" | "link",
  text?,
  attachments?: [{ mediaId, kind?: image|video|audio|file, caption? }],
  linkUrl?
} -> { post }
- GET `/posts/:id` -> { post }
- DELETE `/posts/:id` -> { ok: true }
- GET `/posts` — query: { authorId?, cursor?, limit?, sort: recent|trending }

Reactions (Respect)
- POST `/posts/:id/respect` -> { total }
- DELETE `/posts/:id/respect` -> { total }

Comments
- GET `/posts/:id/comments` — { cursor?, limit? }
- POST `/posts/:id/comments` — body: { text } -> { comment }
- DELETE `/comments/:id` -> { ok: true }

Feeds
- GET `/feed/community` — query: { sort: trending|recent, cursor?, limit? }
- GET `/feed/my` — current user’s posts, query: { cursor?, limit? }

Respect Points
- GET `/points/me` — current user’s totals and latest ledger entries
- GET `/leaderboard` — optional: top users by points (time window)

News (proxy/aggregation for the Home screen)
- GET `/news` — query: { source?, cursor?, limit? } -> list of articles (title, summary, url, image, publishedAt, source)
- GET `/news/:id` — optional if caching; otherwise clients open `url`

IVR (optional integration for voice capture via phone)
- POST `/ivr/call/start` — start outbound call to user to record
- POST `/ivr/webhook/recording` — provider webhook with recording URL -> creates media + post
- POST `/ivr/webhook/status` — call status updates

Moderation & Reports
- POST `/reports` — body: { entityType, entityId, reason }
- GET `/admin/reports` — admin only, list reports
- POST `/admin/reports/:id/resolve` — resolve with action

Notifications
- GET `/notifications` — list for current user
- POST `/notifications/:id/read` — mark as read

Common response shape
- `{ data, error?, cursor? }` for list endpoints with cursor pagination.

---

### 4) Request/Response Examples (concise)

Create text post
```
POST /api/v1/posts
{
  "type": "text",
  "text": "Sharing my vichaar"
}

201
{ "post": { "id": "p_01HV...", "type": "text", "text": "Sharing my vichaar", "stats": {"reactions":0, "comments":0}, "createdAt": "..." } }
```

Create media post with photos/video/audio/file
```
POST /api/v1/posts
{
  "type": "media",
  "text": "My field visit",
  "attachments": [
    { "mediaId": "m_img_01", "kind": "image", "caption": "site photo" },
    { "mediaId": "m_vid_02", "kind": "video" }
  ]
}

201
{ "post": { "id": "p_01HW...", "type": "media", "content": { "text": "My field visit", "attachments": [ {"mediaId":"m_img_01","kind":"image","caption":"site photo"}, {"mediaId":"m_vid_02","kind":"video"} ] }, "stats": {"reactions":0, "comments":0}, "createdAt": "..." } }
```

Respect a post
```
POST /api/v1/posts/p_01HV.../respect
200 { "total": 12 }
```

Community feed (trending)
```
GET /api/v1/feed/community?sort=trending&limit=20
200 { "data": [ { "id": "p_...", "type": "audio", "media": {"url":"..."}, "stats": {"reactions": 42} } ], "cursor": {"next":"..."} }
```

---

### 5) Implementation Plan (phased)

Phase 0 — Foundations
- Env + configuration (`config/env.ts`), pino logger, error handling middleware, request-id, security (helmet, CORS, rate limiting).
- Mongo connection + health endpoint `/healthz`.

Phase 1 — Auth & Profiles
- Minimal password/OTP login (decide one), JWT access/refresh tokens, `GET/PUT /me`, avatar upload presign/complete.

Phase 2 — Posts & Media
- Media presign/complete with storage abstraction.
- Post creation for text/audio/video/link.
- Post fetch by id and delete.

Phase 3 — Reactions, Comments, Points
- Respect add/remove with idempotency; maintain `posts.stats` and write to `points_ledger` for the receiver.
- Comments CRUD (list, create, delete own/admin).
- Points totals endpoint.

Phase 4 — Feeds & News
- Community feed (recent + trending based on reactions/time decay), My posts feed.
- External news provider integration and optional caching.

Phase 5 — IVR & Notifications (optional)
- IVR webhooks to turn call recordings into media + posts.
- Notification scaffolding (on respect/comment).

Phase 6 — Moderation & Admin
- Reports, admin review, takedown actions.

---

### 6) Security, Performance, Ops

- Validation: zod/yup for all request bodies/queries.
- AuthZ: route guards for auth/admin; authors can delete own posts/comments.
- Rate limits: stricter on write endpoints; separate limits for `/ivr/webhook/*`.
- Media: virus scan hooks (provider-side), size/type limits.
- Logging: structured logs with request-id and userId.
- Pagination: cursor-based for feeds and comments.
- Index management: `schemas/mongo/indexes.ts` ensures on startup.
- Observability: `/healthz`, `/readyz` and basic metrics hook (future).

---

### 7) Open Questions / Decisions

- Authentication flow: OTP via SMS vs password. (Plan assumes either; validators will be split accordingly.)
- Storage provider choice: S3-compatible vs Cloudinary.
- News provider contract and caching TTL.
- Trending algorithm: simple reaction count in recent window vs weighted time decay.

This document is an implementation plan only. Do not start coding until explicitly approved.


