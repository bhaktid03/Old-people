# Audio System - Quick Reference Guide

## 🎯 High-Level Flow (30-second explanation)

1. **User records audio** → Saved to device as `.m4a` file
2. **Audio uploaded to FastAPI** → Whisper transcribes → LLM summarizes
3. **Response displayed** → Transcript + AI reply shown in UI
4. **User can playback** → Click Play → Animated waves → Click Pause → Waves stop

---

## 📁 Key Files & Their Roles

| File | Purpose |
|------|---------|
| `audio_recorder.dart` | Records audio to device storage |
| `audio_player_service.dart` | Plays audio (singleton, one at a time) |
| `voice_interpret_service.dart` | Uploads audio to backend, gets transcript + LLM reply |
| `news_detail_screen.dart` | Main screen - manages thoughts list & playback state |
| `viewer_thought_card.dart` | Displays thought with audio player UI + waves |
| `audio_recording_screen.dart` | Recording UI with timer |
| `viewer_thought_model.dart` | Data model for thoughts |

---

## 🔄 State Flow Diagram

```
[Recording]
User clicks "Record" 
  → AudioRecorderService.start()
  → File saved: /documents/audio_123.m4a
  → Return path to NewsDetailScreen

[Upload & Process]
NewsDetailScreen 
  → Create ViewerThought (status: local)
  → VoiceInterpretService.interpretAudio()
  → POST to FastAPI /voice/interpret
  → Backend: Whisper STT → LLM → Response
  → Update ViewerThought (status: uploaded, transcript, llmReply)

[Playback]
User clicks Play
  → AudioPlayerService.togglePlay()
  → just_audio plays file
  → Stream listener: _playingId = thought.id
  → ViewerThoughtCard: isPlaying = true
  → Waves animation starts

[Completion]
Audio finishes
  → Position stream detects: position >= duration
  → Stream listener: _playingId = null
  → ViewerThoughtCard: isPlaying = false
  → Waves animation stops
  → Play button shown
```

---

## 🎨 UI Components

### ViewerThoughtCard
- **Caption**: AI reply (light blue box above player)
- **Play/Pause Button**: Toggles playback
- **Sound Waves**: Animated when playing, static gray bar when not
- **Transcript**: Toggle View/Hide
- **Actions**: Show Respect, Thoughts?

### AudioRecordingScreen
- **Timer**: Shows recording duration
- **Stop Button**: Saves recording
- **Cancel Button**: Discards recording

---

## 🔌 Backend API

### Endpoint: `POST /voice/interpret`

**Request**:
```
FormData:
  - file: audio.m4a (multipart)
  - language: "en" | "hi"
```

**Response**:
```json
{
  "transcript": "User's spoken words...",
  "language": "en",
  "llmReply": "AI-generated summary...",
  "meta": { "duration": 12.5, "sttBackend": "faster-whisper" }
}
```

---

## 📊 Data Model: ViewerThought

```dart
{
  id: "1234567890",
  userName: "You",
  type: ThoughtType.audio,
  localFilePath: "/path/to/audio.m4a",  // Before upload
  audioUrl: "/path/to/audio.m4a",        // For playback
  text: "Transcript text...",            // Local or remote transcript
  remoteTranscript: "Server transcript", // From Whisper
  llmReply: "AI summary...",            // From LLM
  status: ThoughtStatus.uploaded,       // local → uploading → uploaded
  duration: Duration(seconds: 12),
  headlineId: "article_123",
  createdAt: DateTime.now()
}
```

---

## 🎛️ State Management

### Playback State
- **`_playingId`** (in NewsDetailScreen): ID of currently playing audio
  - `null` = Nothing playing → Play button
  - `thought.id` = Playing → Pause button + waves

### Stream Listeners
1. **`playerStateStream`**: Detects playing/paused/completed states
2. **`positionStream`**: Detects when audio reaches end

### Animation Controller
- **`_waveController`**: Controls wave animation
  - `.repeat()` when `isPlaying = true`
  - `.stop() + reset()` when `isPlaying = false`

---

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Waves keep animating after audio stops | Check `didUpdateWidget` stops animation when `isPlaying` becomes false |
| Play button doesn't change to Pause | Ensure stream listener updates `_playingId` when `state.playing = true` |
| Audio doesn't upload | Check network timeout (60s), verify API base URL |
| Transcript not showing | Check `remoteTranscript` field is set after upload |

---

## 🚀 Testing Checklist

- [ ] Record audio → File saved locally
- [ ] Upload audio → Status changes to "uploading"
- [ ] Backend processes → Status changes to "uploaded"
- [ ] Transcript appears in UI
- [ ] AI reply appears as caption
- [ ] Click Play → Button changes to Pause
- [ ] Waves animate when playing
- [ ] Click Pause → Button changes to Play
- [ ] Waves stop when paused
- [ ] Audio completes → Button changes to Play automatically
- [ ] Waves stop when audio completes

---

## 📝 Key Concepts

1. **Singleton Pattern**: AudioPlayerService ensures only one audio plays at a time
2. **Stream-Based Updates**: UI updates reactively via streams (not polling)
3. **Local-First**: Audio saved locally before upload (offline support)
4. **Status Tracking**: ThoughtStatus enum tracks lifecycle (local → uploading → uploaded)
5. **Dual Streams**: State stream + position stream for reliable completion detection

---

## 💡 Architecture Patterns Used

- **Service Layer**: AudioRecorderService, AudioPlayerService, VoiceInterpretService
- **Singleton**: AudioPlayerService (one instance)
- **Stream Subscription**: Reactive state updates
- **State Management**: setState + ValueNotifier pattern
- **Model-View Separation**: ViewerThought model separate from UI

---

## 🔗 File Dependencies

```
news_detail_screen.dart
  ├─ audio_recorder.dart
  ├─ audio_player_service.dart
  ├─ voice_interpret_service.dart
  ├─ viewer_thought_card.dart
  └─ viewer_thought_model.dart

viewer_thought_card.dart
  └─ Uses: AnimationController for waves

audio_player_service.dart
  └─ Uses: just_audio plugin

voice_interpret_service.dart
  └─ Uses: dio (HTTP client)
```

---

## 📱 User Journey

1. **Read article** → NewsDetailScreen
2. **Want to comment** → Click "Share Your Thoughts"
3. **Record voice** → AudioRecordingScreen
4. **Stop recording** → Audio saved, thought created
5. **Upload happens** → Status: uploading → uploaded
6. **See transcript** → Toggle "View Transcript"
7. **See AI summary** → Shown as caption above player
8. **Play audio** → Click Play → Hear recording
9. **See waves** → Visual feedback during playback
10. **Audio finishes** → Auto-reset to Play button

---

## 🎓 Learning Points

1. **Audio Recording**: Use `record` plugin, save to app documents
2. **Audio Playback**: Use `just_audio`, manage with singleton service
3. **Streams**: Listen to player state for real-time UI updates
4. **Multipart Upload**: Use `Dio` with `MultipartFile` for file uploads
5. **Animation**: Use `AnimationController` for visual feedback
6. **State Sync**: Use `didUpdateWidget` to sync animation with playback state

