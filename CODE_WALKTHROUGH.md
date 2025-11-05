# Code Walkthrough: Step-by-Step Execution

This document explains exactly what happens in the code when you record and play audio.

---

## 📝 Recording Audio: Code Execution Path

### Step 1: User Clicks "Share Your Thoughts"

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~156: _showShareThoughtsModal method
void _showShareThoughtsModal(BuildContext context) async {
  final result = await showShareThoughtsModal<String>(context);
  // User selects "record_audio"
  if (result == 'record_audio') {
    // Navigate to recording screen
    final audioResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AudioRecordingScreen()),
    );
```

### Step 2: AudioRecordingScreen Initializes

**File**: `lib/widgets/audio_recording_screen.dart`

```dart
// Line ~25: initState
@override
void initState() {
  super.initState();
  _initRecorderAndSTT(); // Initialize recorder
}

// Line ~30: Initialize recorder
Future<void> _initRecorderAndSTT() async {
  await _speechToText.initialize(...);
  _startRecording(); // Automatically start recording
}
```

### Step 3: Start Recording

**File**: `lib/widgets/audio_recording_screen.dart`

```dart
// Line ~45: _startRecording method
void _startRecording() async {
  try {
    // Call AudioRecorderService
    final path = await _recorderService.start();
    // path = "/data/user/0/com.example.app/documents/audio_1234567890.m4a"
    
    setState(() {
      _isRecording = true;
      _recordedFilePath = path;
      _duration = Duration.zero;
    });
    
    _startTimer(); // Start UI timer
  } catch (e) {
    // Handle error
  }
}
```

**File**: `lib/services/audio_recorder.dart`

```dart
// Line ~14: start method
Future<String?> start() async {
  // 1. Check permission
  final hasPerm = await _recorder.hasPermission();
  if (!hasPerm) throw Exception('Microphone permission not granted');
  
  // 2. Get app documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  // appDocDir.path = "/data/user/0/com.example.app/documents"
  
  // 3. Generate unique file path
  final filePath = '${appDocDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
  // filePath = "/data/user/0/com.example.app/documents/audio_1703123456789.m4a"
  
  _currentFilePath = filePath;
  
  // 4. Start recording with record plugin
  await _recorder.start(
    const RecordConfig(encoder: AudioEncoder.aacLc),
    path: filePath,
  );
  
  return filePath; // Return path to caller
}
```

### Step 4: User Stops Recording

**File**: `lib/widgets/audio_recording_screen.dart`

```dart
// Line ~60: _stopRecording method
void _stopRecording() async {
  _timer?.cancel(); // Stop UI timer
  _stopListening(); // Stop speech-to-text
  
  // Call AudioRecorderService to stop
  final path = await _recorderService.stop();
  // path = "/data/user/0/com.example.app/documents/audio_1703123456789.m4a"
  
  if (path != null) {
    // Return result to NewsDetailScreen
    Navigator.of(context).pop({
      'path': path,
      'duration': _duration, // e.g., Duration(seconds: 12)
      'transcript': _currentTranscript, // e.g., "Hello world"
    });
  }
}
```

**File**: `lib/services/audio_recorder.dart`

```dart
// Line ~25: stop method
Future<String?> stop() async {
  final path = await _recorder.stop(); // Stop recording
  _currentFilePath = null;
  return path; // Return file path
}
```

### Step 5: Back to NewsDetailScreen - Create Thought

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~164: After recording screen returns
if (audioResult != null && mounted) {
  final audioPath = audioResult['path'] as String?;
  final duration = audioResult['duration'] as Duration?;
  final transcript = audioResult['transcript'] as String?;
  
  // Create ViewerThought object
  final newThought = ViewerThought(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userName: 'You',
    type: ThoughtType.audio,
    localFilePath: audioPath, // "/path/to/audio.m4a"
    audioUrl: audioPath,       // Same for now
    duration: duration,         // Duration(seconds: 12)
    text: transcript,          // Local transcript (if available)
    createdAt: DateTime.now(),
    status: ThoughtStatus.local, // Not uploaded yet
    headlineId: widget.headline.id, // Link to article
  );
  
  // Add to thoughts list
  setState(() {
    _thoughts.insert(0, newThought); // Add at top
  });
  
  // Start upload process
  _uploadAudioThought(newThought);
}
```

### Step 6: Upload to Backend

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~238: _uploadAudioThought method
Future<void> _uploadAudioThought(ViewerThought thought) async {
  // Update status to uploading
  setState(() {
    final idx = _thoughts.indexOf(thought);
    _thoughts[idx] = thought.copyWith(status: ThoughtStatus.uploading);
  });
  
  try {
    // Call VoiceInterpretService
    final response = await _voiceInterpretService.interpretAudio(
      thought.localFilePath!,
    );
```

**File**: `lib/services/voice_interpret_service.dart`

```dart
// Line ~10: interpretAudio method
Future<Map<String, dynamic>> interpretAudio(String filePath) async {
  // 1. Read file
  final file = File(filePath);
  if (!await file.exists()) {
    throw Exception('Audio file not found');
  }
  
  // 2. Create multipart form data
  final form = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      file.path,
      filename: file.uri.pathSegments.last,
    ),
    'language': L10n.locale.value, // 'en' or 'hi'
  });
  
  // 3. POST to FastAPI backend
  final response = await _dio.post(
    '/voice/interpret',
    data: form,
    options: Options(contentType: 'multipart/form-data'),
  );
  
  // 4. Return response
  return response.data as Map<String, dynamic>;
  // {
  //   "transcript": "User's spoken words...",
  //   "llmReply": "AI summary...",
  //   "language": "en",
  //   "meta": {...}
  // }
}
```

### Step 7: Backend Processing

**File**: `LLM/main.py`

```python
# Line ~90: /voice/interpret endpoint
@app.post("/voice/interpret")
async def voice_interpret(file: UploadFile, language: str = "en"):
    # 1. Save uploaded file to temp location
    with tempfile.NamedTemporaryFile(delete=True, suffix=".m4a") as tmp_file:
        tmp_file.write(await file.read())
        tmp_file_path = tmp_file.name
    
    # 2. Transcribe with Whisper
    if WHISPER_BACKEND == "faster-whisper":
        segments, info = whisper_model.transcribe(tmp_file_path, language=language)
        transcript = " ".join([segment.text for segment in segments])
    
    # 3. Send to LLM
    llm_response = await summarize_chain.ainvoke({"transcript": transcript})
    llm_reply = llm_response.strip()
    
    # 4. Return response
    return VoiceInterpretResponse(
        transcript=transcript,
        language=info.language,
        llmReply=llm_reply,
        meta={"duration": info.duration}
    )
```

### Step 8: Update Thought with Response

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~200: After backend response
final serverTranscript = (resp['transcript'] as String?)?.trim();
final llmReply = (resp['llmReply'] as String?)?.trim();

setState(() {
  final idx = _thoughts.indexWhere((t) => t.id == thoughtId);
  if (idx != -1) {
    final t = _thoughts[idx];
    _thoughts[idx] = ViewerThought(
      id: t.id,
      userName: t.userName,
      type: t.type,
      text: serverTranscript, // Replace with server transcript
      audioUrl: t.audioUrl,
      createdAt: t.createdAt,
      llmReply: llmReply, // AI-generated summary
      headlineId: t.headlineId,
      status: ThoughtStatus.uploaded, // Mark as uploaded
    );
  }
});
```

---

## 🎵 Playback: Code Execution Path

### Step 1: User Clicks Play Button

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// Line ~199: _AudioRow widget
ElevatedButton.icon(
  onPressed: onPlay, // Callback passed from parent
  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
  label: Text(isPlaying ? L10n.pause : L10n.play),
)
```

### Step 2: onPlay Callback Executes

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~157: onPlay callback
onPlay: () async {
  if (t.audioUrl == null || t.audioUrl!.isEmpty) return;
  
  // Call AudioPlayerService
  await _player.togglePlay(id: t.id, sourcePath: t.audioUrl!);
  
  // Immediately update UI state
  if (mounted) {
    setState(() {
      _playingId = _player.currentId; // Set to thought.id
    });
  }
},
```

### Step 3: AudioPlayerService Toggle Logic

**File**: `lib/services/audio_player_service.dart`

```dart
// Line ~15: togglePlay method
Future<void> togglePlay({required String id, required String sourcePath}) async {
  // Case 1: Same audio is playing → Pause it
  if (_currentId == id && _player.playing) {
    await _player.pause();
    _currentId = null;
    return;
  }
  
  // Case 2: Different audio or not playing → Play it
  // Stop any currently playing audio
  if (_currentId != null && _currentId != id) {
    await _player.stop();
  }
  
  _currentId = id; // Set current playing ID
  await _player.setFilePath(sourcePath); // Load audio file
  await _player.play(); // Start playback
}
```

### Step 4: Stream Listener Reacts

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~38: Stream listener (set up in initState)
_playerStateSubscription = _player.playerStateStream.listen((state) {
  if (!mounted) return;
  
  setState(() {
    if (state.playing && _player.currentId != null) {
      // Audio is playing → Set playing ID
      _playingId = _player.currentId; // Updates to thought.id
    } else {
      // Audio paused or completed → Clear playing ID
      _playingId = null;
      
      // If completed, also stop the player
      if (state.processingState == ProcessingState.completed && 
          _player.currentId != null) {
        _player.stop();
      }
    }
  });
});
```

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~57: Position stream listener
_positionSubscription = _player.positionStream.listen((position) async {
  if (!mounted) return;
  final duration = _player.duration;
  
  // Detect when audio reaches end
  if (duration != null && position >= duration && _playingId != null) {
    setState(() {
      _playingId = null; // Clear playing state
    });
    await _player.stop(); // Stop player
  }
});
```

### Step 5: ViewerThoughtCard Rebuilds

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Line ~154: Building ViewerThoughtCard
..._thoughts.map((t) => ViewerThoughtCard(
  thought: t,
  isPlaying: _playingId == t.id, // true if this thought is playing
  onPlay: () async { ... },
))
```

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// Line ~41: didUpdateWidget detects state change
@override
void didUpdateWidget(ViewerThoughtCard oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  if (widget.isPlaying && !oldWidget.isPlaying) {
    // Started playing → Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isPlaying) {
        _waveController.repeat(); // Start wave animation
      }
    });
  } else if (!widget.isPlaying && oldWidget.isPlaying) {
    // Stopped playing → Stop animation
    _waveController.stop();
    _waveController.reset();
  }
}
```

### Step 6: UI Updates

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// Line ~118: _AudioRow widget
_AudioRow(
  isPlaying: widget.isPlaying, // true/false
  onPlay: widget.onPlay,
  waveController: widget.isPlaying ? _waveController : null,
)
```

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// Line ~213: _AudioRow build method
Expanded(
  child: isPlaying && waveController != null
      ? _SoundWave(controller: waveController!) // Show animated waves
      : Container(
          // Show static gray bar when not playing
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
)
```

### Step 7: Wave Animation

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// Line ~229: _SoundWave widget
class _SoundWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller, // AnimationController
      builder: (context, child) {
        return Row(
          children: List.generate(20, (index) {
            final delay = index * 0.1;
            final value = (controller.value + delay) % 1.0;
            // Calculate wave height using sine function
            final height = 8 + (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 24;
            
            return Container(
              width: 3,
              height: height, // Varies with animation
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.6 + (value * 0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
```

### Step 8: Audio Completes

**File**: `lib/features/headlines/presentation/news_detail_screen.dart`

```dart
// Position stream detects completion
if (duration != null && position >= duration && _playingId != null) {
  setState(() {
    _playingId = null; // Clear playing state
  });
  await _player.stop();
}
```

**File**: `lib/widgets/viewer_thought_card.dart`

```dart
// didUpdateWidget detects isPlaying changed from true to false
else if (!widget.isPlaying && oldWidget.isPlaying) {
  _waveController.stop(); // Stop animation
  _waveController.reset(); // Reset to beginning
}
```

**Result**: UI shows Play button, static gray bar (no waves)

---

## 🔑 Key Code Patterns

### 1. Singleton Pattern
```dart
// AudioPlayerService ensures only one audio plays at a time
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
}
```

### 2. Stream-Based State Updates
```dart
// React to player state changes in real-time
_playerStateSubscription = _player.playerStateStream.listen((state) {
  setState(() {
    // Update UI based on state
  });
});
```

### 3. Animation Controller Lifecycle
```dart
// Start/stop animation based on playback state
if (widget.isPlaying && !oldWidget.isPlaying) {
  _waveController.repeat(); // Start
} else if (!widget.isPlaying && oldWidget.isPlaying) {
  _waveController.stop(); // Stop
  _waveController.reset(); // Reset
}
```

### 4. Status State Machine
```dart
// ThoughtStatus tracks lifecycle
enum ThoughtStatus {
  local,      // Recorded, not uploaded
  uploading,  // Currently uploading
  uploaded,   // Uploaded and processed
  failed,     // Error occurred
}
```

---

## 📊 Data Flow Summary

```
[Recording]
User → AudioRecordingScreen → AudioRecorderService → record plugin → File saved

[Upload]
NewsDetailScreen → VoiceInterpretService → Dio → FastAPI → Whisper → LLM → Response

[Playback]
User → ViewerThoughtCard → NewsDetailScreen → AudioPlayerService → just_audio → Stream events → UI updates
```

---

This walkthrough shows exactly how the code executes from user interaction to UI update!

