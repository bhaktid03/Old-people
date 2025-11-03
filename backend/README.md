# Chaupal Backend (Express + TypeScript)

## Setup
1. Create an `.env` file in `backend/` with:
```
NODE_ENV=development
PORT=4000
MONGODB_URI=<your MongoDB Atlas connection string>
MONGODB_DB=chaupal
GRIDFS_AUDIO_BUCKET=audio
GRIDFS_TTS_BUCKET=tts
```

2. Install deps and run:
```
npm i
npm run dev
```

Health check: `GET http://localhost:4000/health` → `{ ok: true }`

GridFS buckets are initialized as `audio` and `tts` in the configured database.
