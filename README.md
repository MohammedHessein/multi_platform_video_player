# Multi-Platform Video Player

A professional Flutter video player implementation designed for **multiple TV platforms** and **mobile devices** using a single unified codebase.

### ✅ Supported TV Platforms
| Platform | Strategy | Package Format | Build Command |
|----------|----------|----------------|---------------|
| **Android TV** | Native APK | `.apk` | `flutter run` on TV emulator/device |
| **Samsung Tizen** | Flutter Web App | `.wgt` | `flutter build web` → `tizen package` |
| **Samsung Tizen** | Native Flutter-Tizen | `.tpk` | `flutter-tizen build tpk` |
| **LG WebOS** | Flutter Web App | `.ipk` | `flutter build web` → `ares-package` |
| **Apple TV** | macOS proxy | macOS app | `flutter run -d macos` |

### ✅ Supported Mobile Platforms
- **Android Phone** (Touch + Gestures + Double-Tap Seek)
- **iOS Phone** (Touch + Gestures + Double-Tap Seek)

---

## 🎥 Demo Videos
Watch short recordings demonstrating the app running on a Phone and Android TV:
**[Watch Demo Videos on Google Drive](https://drive.google.com/drive/folders/1-i64RZAm3QXiPFASZtMO5baXHH2kpK1B?usp=sharing)**

---

## 📸 Screenshots

### Android TV Experience
<div align="center">
  <img src="./assets/screenshots/tv_1.png" width="250">
  &nbsp;
  <img src="./assets/screenshots/tv_2.png" width="250">
  &nbsp;
  <img src="./assets/screenshots/tv_3.png" width="250">
</div>
<br>

### Mobile Experience

**Portrait Mode**
<div align="center">
  <img src="./assets/screenshots/mobile_1.jpg" width="200">
  &nbsp;
  <img src="./assets/screenshots/mobile_2.jpg" width="200">
  &nbsp;
  <img src="./assets/screenshots/mobile_3.jpg" width="200">
</div>
<br>

**Landscape Mode**
<div align="center">
  <img src="./assets/screenshots/landscape_1.jpg" width="350">
  &nbsp;
  <img src="./assets/screenshots/landscape_2.jpg" width="350">
</div>

---

## 🚀 Key Features
- **Local Asset Video**: Bundled `assets/videos/sample.mp4` plays instantly — no network required.
- **Cross-Platform**: Tailored UI for TV (D-pad optimized) and Phone (Touch/Gesture optimized).
- **Dual Video Backend**: Native `video_player` package for Android/iOS/TV; custom HTML5 `<video>` element for web/TV builds.
- **Protocol-Aware URL Loading**: Web player detects `file://` vs `http://` and picks the right asset path — eliminates long loading hangs on dev servers.
- **Fast-Fail Error Handling**: Web player uses a `Completer` to race `loadedmetadata` vs `error` events — URL failover in milliseconds, not seconds.
- **Double Tap to Seek**: Mobile gesture to seek forward/backward 5 s with animated overlay feedback.
- **Playback Speed Control**: 0.5×–2.0× via bottom sheet on mobile, cycle button on TV.
- **Localization**: Full support for English and Arabic (RTL) with dynamic switching via `EasyLocalization`.
- **Auto-Rotation & Fullscreen**: System-based rotation and immersive landscape mode on mobile.
- **Auto-hide Controls**: Controls fade out after 3 s of inactivity via a coordinated timer state machine.
- **D-pad Navigation**: `FocusableActionDetector` + `Shortcuts` for bulletproof linear focus traversal on all TV platforms.
- **Performance Optimized**: 
    - **Rebuild Isolation**: Video layer is cached in `initState` to prevent DOM re-registration.
    - **Pressure Reduction**: Switched from `timeupdate` events to `500ms` polling to save CPU cycles on TVs.
    - **Listenable Seek Bar**: Bypasses Bloc state rebuilds for smooth 60fps progress updates.
- **Unit Tested**: Core Cubit logic covered by automated tests.
- **Clean Architecture**: Feature-driven modular structure with SOLID principles throughout.

---

## 🛠 Tech Stack & Packages
| Package | Purpose |
|---------|---------|
| `video_player` | Native video playback (Android / iOS / TV) |
| `video_player_tizen` | Tizen implementation for `video_player` (required alongside `video_player` for `.tpk`) |
| `flutter_bloc` | Cubit state management |
| `flutter_screenutil` | Responsive scaling (phone vs TV logical pixels) |
| `equatable` | Value-based state comparison for selective rebuilds |
| `bloc_test` | Cubit unit testing framework |
| `mocktail` | Mocking library for tests |

---

## 📖 Documentation
| Document | Description |
|----------|-------------|
| [🏗 Architecture & Patterns](docs/architecture.md) | Clean Architecture layers, design patterns, dependency graph |
| [🧪 Technical Deep Dive](docs/technical_deep_dive.md) | TV focus, web loading fix, performance, lifecycle, exit handling |
| [🔄 Feature & Interaction Flow](docs/feature_flow.md) | Initialization, state machine, interaction tables, error handling |
| [🧱 Component Breakdown](docs/components.md) | Every UI widget and its purpose |
| [📄 Detailed File Breakdown](docs/detailed_file_breakdown.md) | All files, their responsibilities, and key logic |
| [📺 LG & Samsung TV Guide](lg_and_samsung_tv_guide.md) | Full deployment guide for webOS & Tizen |

---

## 🏃 How to Run (5-Minute Setup)
*No internet or external asset downloads required — local video is bundled.*

```bash
# 1. Clone & install
git clone <repo_url>
cd multi_platform_video_player
flutter pub get

# 2. Mobile (Android / iOS)
flutter run

# 3. Android TV emulator or physical device
#    Start a TV emulator from Android Studio Device Manager, then:
flutter run

# 4. Flutter Web (dev server — Chrome)
flutter run -d chrome

# 5. Samsung Tizen (Web .wgt) — video works on T-10.0 emulator; see lg_and_samsung_tv_guide.md
flutter build web --release --no-web-resources-cdn
node patch_tv_js.js
tizen package -t wgt -s <tizen_security_profile> -- ./build/web
tizen install -s <device_serial> -n "build/web/Multi Platform Video Player.wgt"
# Launch (if sdb is not on PATH, use full path):
# C:\tizen-studio\tools\sdb.exe -s <device_serial> shell "app_launcher -s tIzeNPlAyR.MultiPlatformVideoPlayer"

# 6. LG WebOS (.ipk)
#    Option A: Fastest Development (Hosted local HTTP)
.\scripts\run_webos_hosted.ps1

#    Option B: Production Packaging (.ipk)
.\scripts\run_webos_packaged.ps1

# 7. Samsung Tizen (Native .tpk — requires flutter-tizen)
#    flutter-tizen has no --web flag; use .wgt (above) for web-on-TV testing.
flutter-tizen run -d <device_serial>
# Or: flutter-tizen build tpk --device-profile=tv --security-profile=<samsung_tv_profile>

# 8. Apple TV layout proxy (macOS)
flutter run -d macos
# Use keyboard arrow keys to navigate the TV focus interface
```

---

## 📺 TV Platform Details

### Android TV (Native — Fully Supported)
- Native APK with Leanback launcher intent in `AndroidManifest.xml`.
- `UiModeManager` detection via `MethodChannel` at runtime.
- `FocusableActionDetector` + `Shortcuts` for D-pad navigation.
- Linear focus traversal overrides Flutter's spatial algorithm.

### Samsung Tizen (Web App — Recommended for emulator video)
- `web/config.xml` configures the app as a Tizen TV widget (profile=tv, fullscreen, internet privilege).
- Pipeline: `flutter build web` → `node patch_tv_js.js` → `tizen package -t wgt` → `tizen install -s <serial>`.
- `kIsWeb == true` → TV mode + `WebAppVideoPlayer` (HTML5 `<video>`).
- **Emulator**: install `.wgt` on **`T-10.0-x86_64`** with a **Tizen** certificate profile (not Samsung TV cert). **`T-samsung-10.0-x86_64` does not support `.wgt` install** (`appcmd_support: disabled`).
- For day-to-day UI/video dev without a TV: `flutter run -d chrome`.

### Samsung Tizen (Native `.tpk` — flutter-tizen)
- Uses the community [flutter-tizen](https://github.com/flutter-tizen/flutter-tizen) toolchain + `video_player_tizen`.
- `Platform.isLinux == true` → TV mode + `NativeAppVideoPlayer`.
- **`TizenSafeVideoPlayerPlatform`** (registered in `main.dart`) prevents crashes when the TV emulator returns `Function not implemented` for playback speed / position polling.
- **TV emulator limitation**: `video_player_tizen` does **not** render video frames on TV emulators (black screen; seek/controls may still work). Test visible video via Chrome or `.wgt` on `T-10.0-x86_64`, or on a **physical Samsung TV** for native `.tpk`.
- Playback speed UI is hidden on native Tizen only; speed remains available on Android, iOS, web, and Web TV.

### LG WebOS (Flutter Web — Standard Approach)
- `web/appinfo.json` configures the webOS package metadata.
- `ares-package --no-minify` bundles the Flutter Web build into a `.ipk`.
- `patch_tv_js.js` patches `flutter_bootstrap.js` post-build: sets `canvasKitBaseUrl: "canvaskit/"` so CanvasKit loads from the local bundle (not CDN) and `base href="./"` for `file://` compatibility.

### Apple TV (macOS Proxy — Experimental)
- No official tvOS Flutter support yet.
- macOS target proxies the TV layout — same D-pad focus code maps to keyboard arrows.

---

## 💡 Future Improvements
- **Brightness/Volume Gestures**: Vertical swipe on phones for system controls.
- **Picture-in-Picture (PiP)**: Native PiP for multitasking.
- **Network Streaming + Caching**: HLS/DASH support with buffering strategy.
- **Subtitles**: `.srt` / `.vtt` parsing for multilingual support.

---

## ⚖️ Evaluation Criteria Addressed
- **Multi-TV Platform Support**: Android TV (native), Samsung Tizen (web + native), LG WebOS (web), Apple TV (macOS proxy).
- **Code Quality**: Clean Architecture, SOLID principles, Dart best practices, abstract player interface.
- **TV Usability**: `FocusableActionDetector`, custom `Shortcuts`, linear focus traversal, and auto-hide.
- **Setup Speed**: Single `flutter run` for mobile/Android TV — no extra tooling required.

---
Developed as a technical task for **e& Egypt**.
