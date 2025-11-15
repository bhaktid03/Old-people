# Chaupal - Voice-First Community App for Elders

A Flutter-based mobile application designed to empower elderly users to share their thoughts on news articles, connect with their community, and access information through voice-first interactions.

## 📱 Project Overview

**Chaupal** is a voice-first community platform that addresses the digital divide faced by elderly users in India. The app enables users to:
- Read curated news headlines with text-to-speech support
- Share their thoughts via voice recordings (auto-transcribed)
- Engage with community posts through respectful interactions (Sammaan/Gyaan)
- Access an AI assistant (Sathi) for help and companionship
- Participate in small voice circles for meaningful conversations

### Target Audience
- Elderly users (65+) in India
- Users with varying levels of digital literacy
- Hindi and English speakers
- Users who prefer voice interactions over typing

## 🛠 Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **Networking**: Custom ApiClient (dart:io) + Dio for multipart uploads
- **Audio**: `record` (recording), `just_audio` (playback), `flutter_tts` (TTS)
- **Localization**: `intl` with ARB files (Hindi/English)

### Backend
- **AI Services**: FastAPI (Python)
  - Speech-to-Text: OpenAI Whisper
  - LLM: Google Gemini 2.5 Flash (via LangChain)
- **Main API**: Node.js/Express (planned)
- **Database**: MongoDB Atlas + GridFS (audio storage)

### Why This Tech Stack?

#### Flutter
- **Cross-platform efficiency**: Single codebase for Android and iOS
- **Accessibility-first**: Built-in widgets for WCAG AAA compliance
- **Performance**: Native compilation ensures smooth animations
- **Rich ecosystem**: Pre-built packages for audio, TTS, and localization

#### FastAPI
- **AI/ML integration**: Excellent Python ecosystem for Whisper and LangChain
- **Async architecture**: Handles concurrent transcription requests efficiently
- **Type safety**: Pydantic models ensure data validation
- **Auto-documentation**: OpenAPI docs facilitate integration

#### MongoDB Atlas + GridFS
- **Flexible schema**: Document model accommodates evolving features
- **Native audio storage**: GridFS eliminates need for external S3
- **Scalability**: Automatic scaling and global distribution
- **Cost-effective**: Free tier suitable for MVP

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Python 3.9+ (for LLM service)
- MongoDB Atlas account (free tier)
- Android Studio / Xcode (for mobile development)
- Google API Key (for Gemini LLM)

### Installation

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd Old-people
```

#### 2. Frontend Setup

```bash
# Install Flutter dependencies
flutter pub get

# Configure environment variables
# Create .env file in root directory
# Add: LLM_BASE_URL=http://127.0.0.1:8000
```

#### 3. Backend Setup (LLM Service)

```bash
cd LLM

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
# Create .env file in LLM directory
# Add: GOOGLE_API_KEY=your_api_key_here
# Add: WHISPER_MODEL=base  # or small, medium, large-v2
```

#### 4. Run the Application

**Start LLM Service:**
```bash
cd LLM
python main.py
# Service runs on http://127.0.0.1:8000
```

**Start Flutter App:**
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

### Configuration

#### Backend URL Configuration
Update `lib/api/common/endpoints.dart`:
- **Android Emulator**: `http://10.0.2.2:4000` (main API) / `http://10.0.2.2:8000` (LLM)
- **iOS Simulator**: `http://localhost:4000` / `http://localhost:8000`
- **Physical Device**: `http://YOUR_LOCAL_IP:4000` / `http://YOUR_LOCAL_IP:8000`

#### MongoDB Connection
Configure MongoDB Atlas connection string in backend environment variables.

## 📚 Features

### 1. Headlines Feed
- Curated news headlines (3-5 per day)
- Large, readable text with high contrast
- Text-to-speech "Listen" button
- Tap to view full article

### 2. Voice Post Creation
- Record thoughts via voice (M4A format)
- Automatic transcription (Whisper STT)
- Transcript confirmation before posting
- Link posts to specific headlines

### 3. Community Feed
- Scrollable feed of approved voice posts
- Audio player with waveform animation
- Reactions: "Sammaan" (Respect) and "Gyaan" (Insightful)
- Comment threading
- Infinite scroll pagination

### 4. Sathi AI Assistant
- Voice-first interaction
- Context-aware help and guidance
- Multilingual support (Hindi/English)
- Empathetic, elder-friendly responses

### 5. Profile Management
- View "My Vichaars" (thoughts)
- Respect points counter
- Edit profile with photo upload
- Language and accessibility preferences

## 🎨 Accessibility Features

### Visual
- Base font size: 18sp (configurable up to 28sp)
- High-contrast color scheme (WCAG AAA: 7:1+ ratios)
- Large icons (32-48dp) with text labels
- Focus indicators for keyboard navigation

### Motor
- Minimum tap targets: 56×56dp
- Spacing between elements: 8-12dp
- Haptic feedback on interactions
- Confirmation dialogs for destructive actions

### Cognitive
- Consistent navigation patterns
- Clear, action-oriented labels
- Plain-language error messages
- Loading states with progress indicators

### Auditory
- Text-to-speech for all content
- Visual indicators for audio playback
- Transcripts for all audio content
- Adjustable TTS speed (0.85x - 1.0x)

## 📁 Project Structure

```
Old-people/
├── lib/
│   ├── api/              # API clients and repositories
│   ├── features/         # Feature modules (auth, headlines, post, feed, etc.)
│   ├── services/         # Cross-cutting services (audio, TTS, voice)
│   ├── widgets/          # Reusable UI components
│   ├── core/             # Core utilities (network, localization, accessibility)
│   └── main.dart         # Application entry point
├── LLM/                  # FastAPI backend (AI services)
│   ├── main.py           # FastAPI application
│   └── requirements.txt  # Python dependencies
├── assets/
│   ├── i18n/             # Localization files (app_en.arb, app_hi.arb)
│   └── sathi_logo.png
├── android/              # Android-specific code
├── ios/                  # iOS-specific code
└── pubspec.yaml          # Flutter dependencies
```

## 🔧 Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Code Style
- Follow Flutter/Dart style guide
- Use `flutter analyze` to check code quality
- Format code with `dart format`

## 📖 Documentation

- [Implementation Phase Documentation](./IMPLEMENTATION_PHASE_DOCUMENTATION.md): Comprehensive technical documentation
- [Implementation Plan](./IMPLEMENTATION_PLAN.md): Detailed implementation roadmap
- [Quick Start Guide](./QUICK_START.md): Quick setup instructions
- [Quick Reference](./QUICK_REFERENCE.md): Audio system reference

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code of Conduct
- Be respectful and inclusive
- Prioritize accessibility in all contributions
- Test changes with target user demographics in mind

## 📄 License

[Add your license here]

## 🙏 Acknowledgments

- Design insights from human-centered design research
- Community feedback from elderly users during usability testing
- Open-source libraries and frameworks that made this possible

## 📞 Contact

[Add contact information]

---

**Built with ❤️ for elderly users in India**

