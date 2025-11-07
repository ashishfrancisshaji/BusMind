# BusMind - AI-Powered Productivity App for Bus Commuters

**Author**: Ashish P Shaji  
**Copyright © 2024 Ashish P Shaji. All Rights Reserved.**

---

BusMind is a comprehensive Flutter application designed to transform bus commutes into productive learning and wellness experiences for students and commuters worldwide. Using AI-powered mood detection, emotion-aware music, smart flashcards, posture monitoring, and voice summarization, BusMind helps you make the most of your travel time.

## 🚀 Key Features

### 🧠 AI Mood Detection
- **Real-time Facial Analysis**: Uses camera and OpenCV for accurate emotion detection
- **Multi-Model AI**: Combines custom TensorFlow Lite models with cloud-based inference
- **Smart Recommendations**: Suggests activities based on detected emotional state
- **Confidence Scoring**: Shows accuracy of mood detection with visual feedback
- **Personalized Insights**: Learns your patterns and adapts over time

### 🎵 Emotion-Aware Music Player
- **Mood-Based Playlists**: Automatically suggests music matching your emotional state
- **Multiple Genres**: Focus, relaxing, energizing, ambient, classical, and lo-fi
- **Full Playback Controls**: Play, pause, skip, shuffle, and repeat
- **Audio Progress**: Visual progress tracking with duration display
- **Smart Queue Management**: Dynamic playlist generation based on mood

### 📚 Smart Flashcards with AI
- **AI-Generated Cards**: Create flashcards from voice recordings, notes, and summaries using Gemini AI
- **Category Organization**: Organize cards by subject, topic, or custom categories
- **Difficulty Tracking**: Mark cards as easy, medium, or hard for spaced repetition
- **Progress Analytics**: Track your learning progress with detailed statistics
- **Interactive Study**: Smooth flip animations and intuitive study interface
- **Import/Export**: Share flashcard sets with others

### 🏃‍♂️ Real-Time Posture Monitoring
- **Sensor-Based Detection**: Uses accelerometer and gyroscope for posture analysis
- **Smart Alerts**: Gentle vibration and visual reminders for poor posture
- **Health Statistics**: Track good posture percentage over time
- **Customizable Settings**: Adjust sensitivity and alert intervals
- **Session Tracking**: Monitor posture quality during each commute

### 🎤 Voice Summarization
- **Speech-to-Text**: Record lectures, meetings, or notes with high accuracy
- **AI-Powered Summaries**: Generate concise summaries with key points using HuggingFace models
- **Searchable History**: Find past recordings and summaries easily
- **Flashcard Integration**: Automatically convert summaries into study cards
- **Multiple Languages**: Support for various languages and accents

### 📊 Analytics & Insights
- **Usage Tracking**: Monitor time spent on each feature
- **Learning Progress**: Track flashcard mastery and study sessions
- **Mood Patterns**: Analyze emotional trends over time
- **Posture Health**: View posture quality statistics and improvements
- **Custom Reports**: Generate detailed analytics reports

### 🔐 Authentication & Privacy
- **Secure Login**: User authentication with encrypted storage
- **Local Data Storage**: All personal data stored securely on device using Hive
- **Privacy First**: Camera and sensor data processed locally
- **API Key Management**: Secure handling of AI service credentials

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter (Dart) with Material Design 3
- **State Management**: Provider pattern for reactive UI
- **Navigation**: GoRouter for declarative routing
- **Local Storage**: Hive for fast, encrypted local database
- **Preferences**: SharedPreferences for settings

### AI & Machine Learning
- **Emotion Detection**: 
  - Custom TensorFlow Lite model (emotion_model.tflite)
  - OpenCV for image processing
  - Real-time face detection and classification
- **Natural Language Processing**:
  - Google Gemini AI for flashcard generation
  - HuggingFace Inference API for text summarization
- **Speech Recognition**: Speech-to-Text with local processing

### Sensors & Hardware
- **Camera**: High-performance camera integration for mood detection
- **Audio**: 
  - AudioPlayers for music playback
  - Record package for voice recording
  - Speech-to-Text for transcription
- **Motion Sensors**: 
  - Accelerometer and gyroscope via sensors_plus
  - Real-time posture analysis algorithms
- **Haptics**: Vibration feedback for alerts

### Services Architecture
- **AI Algorithms Service**: Core AI logic and model management
- **Auto Prompt Service**: Intelligent prompt generation for AI features
- **ML Service**: TensorFlow Lite model inference
- **OpenCV Emotion Service**: Advanced facial emotion detection

## 📱 Project Structure

```
lib/
├── main.dart                           # App entry point
├── core/
│   ├── app_theme.dart                  # Material Design theme
│   └── router.dart                     # GoRouter configuration
├── providers/
│   ├── analytics_provider.dart         # Analytics tracking
│   ├── app_state_provider.dart         # Global app state
│   ├── auth_provider.dart              # Authentication logic
│   ├── flashcard_adapter.dart          # Hive adapter for flashcards
│   ├── flashcard_provider.dart         # Flashcard state & AI generation
│   ├── mood_detection_provider.dart    # Mood detection state
│   ├── music_provider.dart             # Music playback logic
│   ├── posture_provider.dart           # Posture monitoring state
│   └── voice_provider.dart             # Voice recording & summarization
├── screens/
│   ├── splash_screen.dart              # App loading screen
│   ├── onboarding_screen.dart          # First-time user experience
│   ├── auth_screen.dart                # Login/signup
│   ├── home_screen.dart                # Main dashboard
│   ├── mood_detection_screen.dart      # Mood analysis interface
│   ├── flashcards_screen.dart          # Flashcard study interface
│   ├── music_screen.dart               # Music player
│   ├── posture_screen.dart             # Posture monitoring
│   ├── voice_summary_screen.dart       # Voice recording & summaries
│   ├── analytics_screen.dart           # Usage statistics
│   └── profile_screen.dart             # User profile & settings
├── services/
│   ├── ai_algorithms_service.dart      # Core AI algorithms
│   ├── auto_prompt_service.dart        # AI prompt generation
│   ├── ml_service.dart                 # TensorFlow Lite inference
│   └── opencv_emotion_service.dart     # OpenCV emotion detection
├── widgets/
│   ├── analytics_tracker.dart          # Analytics widget
│   ├── custom_app_bar.dart             # Reusable app bar
│   ├── custom_back_button.dart         # Custom navigation button
│   ├── feature_card.dart               # Dashboard feature cards
│   ├── quick_stats_card.dart           # Statistics display
│   └── trip_status_card.dart           # Trip status widget
├── secrets/
│   ├── api_keys.dart                   # API keys (gitignored)
│   └── api_keys.example.dart           # Example template
└── assets/
    ├── models/
    │   └── emotion_model.tflite        # Emotion detection model
    └── sounds/
        └── alarm.mp3                   # Alert sound
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK (API level 21+) or iOS 12.0+
- Active internet connection for AI features

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/busmind.git
   cd busmind
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys** ⚠️ **IMPORTANT**
   
   Create `lib/secrets/api_keys.dart` from the example:
   ```bash
   cp lib/secrets/api_keys.example.dart lib/secrets/api_keys.dart
   ```
   
   Then edit `lib/secrets/api_keys.dart` and add your keys:
   ```dart
   class ApiKeys {
     static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
     static const String huggingFaceToken = 'YOUR_HUGGINGFACE_TOKEN_HERE';
   }
   ```

   **Get API Keys:**
   - **Gemini API**: [Get from Google AI Studio](https://makersuite.google.com/app/apikey)
   - **HuggingFace Token**: [Create at HuggingFace](https://huggingface.co/settings/tokens)

4. **Add TensorFlow Lite Model**
   
   Place your trained emotion detection model at:
   ```
   assets/models/emotion_model.tflite
   ```

5. **Platform-specific Setup**

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.VIBRATE" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>BusMind needs camera access for mood analysis</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>BusMind needs microphone access for voice features</string>
   <key>NSMotionUsageDescription</key>
   <string>BusMind needs motion sensors for posture monitoring</string>
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### AI Service Configuration

The app uses multiple AI services configured in the providers:

**Gemini AI** (Flashcard generation):
- Configured in `flashcard_provider.dart`
- Generates smart flashcards from text/voice input
- Supports multiple subjects and difficulty levels

**HuggingFace** (Text summarization):
- Configured in `voice_provider.dart`
- Summarizes voice recordings and long texts
- Extracts key points automatically

**Custom TensorFlow Lite** (Emotion detection):
- Model: `assets/models/emotion_model.tflite`
- Processes camera frames locally for privacy
- Real-time emotion classification

### Camera Settings

Adjust camera quality in `mood_detection_provider.dart`:
```dart
// Higher resolution for better accuracy
ResolutionPreset.high

// Or lower for better performance
ResolutionPreset.medium
```

### Posture Monitoring Sensitivity

Modify in `posture_provider.dart`:
```dart
static const double _postureThreshold = 15.0; // degrees
static const Duration _checkInterval = Duration(seconds: 30);
```

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔒 Security & Privacy

### API Key Protection
- All API keys stored in `lib/secrets/api_keys.dart`
- File is git-ignored to prevent accidental commits
- Example file provided for easy setup

### Data Privacy
- Camera data processed locally on device
- No images or video uploaded to servers
- Voice recordings stored locally in Hive
- User data encrypted at rest
- Analytics data anonymized

### Permissions
- Camera: Only for mood detection, processed locally
- Microphone: Only for voice recording
- Sensors: Only for posture monitoring
- Internet: Only for AI API calls (optional, can work offline)

## 🚧 Development Status

### ✅ Completed Features
- [x] Complete UI/UX design with Material Design 3
- [x] Camera integration and face detection
- [x] Custom TensorFlow Lite emotion detection
- [x] OpenCV emotion service
- [x] Gemini AI flashcard generation
- [x] HuggingFace text summarization
- [x] Music player with mood-based selection
- [x] Posture monitoring with sensor fusion
- [x] Voice recording and transcription
- [x] Analytics and usage tracking
- [x] Local data persistence with Hive
- [x] Authentication system
- [x] Onboarding experience

### 🔄 In Progress
- [ ] Advanced emotion analysis with multiple models
- [ ] Personalized AI recommendations
- [ ] Study plan generation
- [ ] Social sharing features

### 📋 Planned Features
- [ ] Offline mode for all features
- [ ] Cloud backup and sync
- [ ] Multi-device support
- [ ] Collaborative flashcard sets
- [ ] Advanced analytics dashboard
- [ ] Gamification and achievements
- [ ] Integration with calendar apps
- [ ] Export reports (PDF, CSV)

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
   - Follow Flutter style guide
   - Add tests for new features
   - Update documentation
4. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable names
- Comment complex logic
- Keep functions small and focused

## 📝 Git Workflow

### Before First Push

1. **Create .gitignore** (if not exists):
   ```bash
   touch .gitignore
   ```

2. **Add this to .gitignore**:
   ```gitignore
   # Flutter/Dart
   .dart_tool/
   .flutter-plugins
   .flutter-plugins-dependencies
   .packages
   .pub-cache/
   .pub/
   build/
   
   # API Keys - CRITICAL!
   lib/secrets/api_keys.dart
   
   # IDE
   .vscode/
   .idea/
   *.iml
   
   # Platform
   .DS_Store
   android/.gradle
   android/local.properties
   ios/Pods/
   ios/.symlinks/
   ```

3. **Initialize and push**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit - BusMind app"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/busmind.git
   git push -u origin main
   ```

### Regular Updates
```bash
git add .
git commit -m "Description of changes"
git push
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Gemini AI for flashcard generation
- HuggingFace for transformer models
- TensorFlow team for TensorFlow Lite
- OpenCV community for computer vision tools
- All open-source contributors

## 📞 Support & Contact

If you encounter issues or have questions:

1. **Check existing issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/busmind/issues)
2. **Create new issue**: Provide detailed information and steps to reproduce
3. **Discussions**: Join conversations in the Discussions tab

## 🌟 Show Your Support

If BusMind helps you, please:
- ⭐ Star this repository
- 🐛 Report bugs
- 💡 Suggest features
- 🤝 Contribute code
- 📢 Share with others

## 🔮 Vision

BusMind aims to become the ultimate companion for students and commuters worldwide, transforming every bus ride into an opportunity for productivity, learning, and wellness. We envision a future where commute time is no longer wasted but becomes a valuable part of your daily growth journey.

---

**Made with ❤️ for bus commuters everywhere**

*Transform your commute, transform your life.*