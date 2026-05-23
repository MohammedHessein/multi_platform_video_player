# Detailed File-by-File Breakdown

This document provides a responsibility analysis for every file in the project.

---

## 1. Project Entry Points

### 📂 [main.dart](file:///d:/e_and/multi_platform_video_player/lib/main.dart)
- **Responsibility**: The application's main entry point.
- **Key Logic**:
  - Initializes `WidgetsFlutterBinding`.
  - On native Tizen (`Platform.isLinux`), calls `TizenSafeVideoPlayerPlatform.install()` before any `VideoPlayerController` is created.
  - Calls `PlatformUtils.initialize()` to detect TV vs Phone at startup.
  - Configures `SystemChrome` for immersive mode and locks orientation to landscape on TV.
  - Wraps the root widget in `EasyLocalization` and `MultiPlatformVideoPlayerApp`.

### 📂 [lib/app.dart](file:///d:/e_and/multi_platform_video_player/lib/app.dart)
- **Responsibility**: Root widget configuration.
- **Key Logic**:
  - Configures `MaterialApp` with the app theme from `AppTheme`.
  - Sets `VideoPlayerScreen` as the home route.

---

## 2. Core Layer (`lib/core/`)

### 📂 [constants/app_constants.dart](file:///d:/e_and/multi_platform_video_player/lib/core/constants/app_constants.dart)
- **Responsibility**: Centralized design tokens and configuration values.
- **Key Logic**:
  - Defines `tvDesignSize` (960×540) and `phoneDesignSize` (360×690) for responsive scaling.
  - Standardizes TV button sizes, animation durations, seek amounts, and the `MethodChannel` name.

### 📂 [constants/app_colors.dart](file:///d:/e_and/multi_platform_video_player/lib/core/constants/app_colors.dart)
- **Responsibility**: Application color palette.
- **Key Logic**:
  - Implements a "Video-First" dark theme with high-contrast focus colors (`AppColors.primary` / `AppColors.focused`) for 10-foot TV visibility.

### 📂 [constants/app_strings.dart](file:///d:/e_and/multi_platform_video_player/lib/core/constants/app_strings.dart)
- **Responsibility**: Centralized UI strings and labels.

### 📂 [theme/app_theme.dart](file:///d:/e_and/multi_platform_video_player/lib/core/theme/app_theme.dart)
- **Responsibility**: `ThemeData` configuration.
- **Key Logic**:
  - Applies dark mode globally with `AppColors` tokens.

### 📂 [utils/platform_utils.dart](file:///d:/e_and/multi_platform_video_player/lib/core/utils/platform_utils.dart)
- **Responsibility**: Unified runtime platform detection.
- **Key Logic**:
  - **Android TV**: Uses a `MethodChannel` to query native `UiModeManager.getCurrentModeType()` — the only way to distinguish Android TV from an Android Phone in a single APK.
  - **Web (Tizen / WebOS)**: `kIsWeb == true` → TV mode.
  - **macOS**: TV mode (Apple TV proxy).
  - **Linux**: TV mode (covers `flutter-tizen` native builds, which run on a Linux-based OS).
  - Exposes `isTV`, `isPhone`, `isWebTv`, and `isTizenNative` (`!kIsWeb && Platform.isLinux`) getters consumed throughout the app.

### 📂 [platform/tizen_safe_video_player_platform.dart](file:///d:/e_and/multi_platform_video_player/lib/core/platform/tizen_safe_video_player_platform.dart)
- **Responsibility**: Decorator around `VideoPlayerPlatform` for native flutter-tizen builds.
- **Key Logic**:
  - Installed from `main.dart` after plugin registration.
  - Swallows `Function not implemented` for `setPlaybackSpeed` and returns a cached position when `getPosition` fails — prevents emulator crashes from `video_player`'s internal polling timer.

### 📂 [utils/duration_extension.dart](file:///d:/e_and/multi_platform_video_player/lib/core/utils/duration_extension.dart)
- **Responsibility**: `Duration` formatting helper.
- **Key Logic**:
  - Adds a `toFormattedString()` extension that formats durations as `mm:ss` for the seek bar display.

---

## 3. Video Player Feature (`lib/features/video_player/`)

### 📂 [cubit/video_player_cubit.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/cubit/video_player_cubit.dart)
- **Responsibility**: The "Brain" of the player — single source of truth for all state.
- **Key Logic**:
  - **Initialization**: On web (`PlatformUtils.isWebTv`), creates a `WebAppVideoPlayer`; otherwise creates a `NativeAppVideoPlayer` backed by the `video_player` package.
  - **Lifecycle**: Implements `WidgetsBindingObserver` to pause on app background.
  - **Timers**: `_controlsTimer` auto-hides controls after 3 s; `_statusOverlayTimer` flashes the play/pause icon.
  - **Failover**: On web, `initialize()` iterates candidate URLs until one loads successfully.

### 📂 [cubit/video_player_state.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/cubit/video_player_state.dart)
- **Responsibility**: Immutable state definition using `Equatable`.
- **Key Logic**:
  - Fine-grained `props` list enables selective UI rebuilds via `BlocBuilder`'s `buildWhen`.

### 📂 [player/app_video_player.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/app_video_player.dart)
- **Responsibility**: Abstract interface for all player backends.
- **Key Logic**:
  - Defines the contract: `initialize`, `play`, `pause`, `seekTo`, `setLooping`, `setVolume`, `setPlaybackSpeed`, `addListener`, `removeListener`, `dispose`, `buildView`, and `value`.

### 📂 [player/app_video_player_value.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/app_video_player_value.dart)
- **Responsibility**: Immutable value object for player state.
- **Key Logic**:
  - Holds `duration`, `position`, `isInitialized`, `isPlaying`, `isBuffering`, and `aspectRatio`.

### 📂 [player/native_app_video_player.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/native_app_video_player.dart)
- **Responsibility**: Native player backend for Android, iOS, macOS, Android TV, and native Tizen (`.tpk` via `video_player` + `video_player_tizen`).
- **Key Logic**:
  - Wraps the official `video_player` package's `VideoPlayerController`.
  - Bridges `VideoPlayerValue` ↔ `AppVideoPlayerValue` so the Cubit stays platform-agnostic.
  - `setPlaybackSpeed` catches `PlatformException` so UI speed changes do not surface as unhandled errors on constrained Tizen builds.

### 📂 [player/web_app_video_player.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/web_app_video_player.dart)
- **Responsibility**: HTML5 `<video>` backend for LG webOS and Samsung Tizen web builds.
- **Key Logic**:
  - **Rebuild Stability**: Exposes a stable view via `buildView()`.
  - **Pressure Reduction**: Uses a `500ms` polling timer for position updates instead of the intensive `timeupdate` event.
  - **Smart Attributes**: Sets `preload = 'none'` and `objectFit = 'fill'` for TV engine compatibility.
  - **Protocol-aware URL candidates**: On `file://` (packaged `.ipk`/`.wgt`), tries `media/<file>` first. On `http://https://` (dev server / hosted), tries `assets/assets/<path>` first.
  - **Fast-fail error handling**: `_loadSource` uses a `Completer` that races `onLoadedMetadata` vs `onError`. A 404 or codec error rejects in milliseconds, enabling instant failover to the next candidate URL.

### 📂 [player/app_video_player_factory.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/app_video_player_factory.dart)
- **Responsibility**: Conditional import entry point for player factory.

### 📂 [player/app_video_player_factory_io.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/app_video_player_factory_io.dart)
- **Responsibility**: Returns `NativeAppVideoPlayer` on non-web targets.

### 📂 [player/app_video_player_factory_web.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/player/app_video_player_factory_web.dart)
- **Responsibility**: Returns `WebAppVideoPlayer` on web targets.

---

### 📂 [screens/video_player_screen.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/screens/video_player_screen.dart)
- **Responsibility**: Main screen entry point.
- **Key Logic**:
  - Provides `VideoPlayerCubit` directly via `BlocProvider`.
  - Simple full-screen scaffold containing the `VideoView`.

---

### 📂 [widgets/video_view.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/video_view.dart)
- **Responsibility**: Main view orchestrator — selects between TV and Phone UI.
- **Key Logic**:
  - On **Web TV**: renders `WebTvVideoLayout`.
  - On **Native TV**: renders `TvControls` over the `AspectRatio`-wrapped video.
  - On **Phone**: renders `PhoneControls` with gesture support.
  - `buildWhen` ignores `position`/`duration` changes to prevent full-tree rebuilds during playback.

### 📂 [widgets/web_tv_video_layout.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/web_tv_video_layout.dart)
- **Responsibility**: Full-screen layout for web/TV builds.
- **Key Logic**:
  - Places `WebVideoSurface` (the `HtmlElementView`) as a full-screen background.
  - Overlays `TvControls` on top for D-pad interaction.

### 📂 [widgets/web_video_surface.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/web_video_surface.dart)
- **Responsibility**: Renders the HTML5 `<video>` element inside the Flutter widget tree.
- **Key Logic**:
  - **Optimization**: Caches the `HtmlElementView` widget in `initState` to prevent it from being rebuilt when Bloc states change.
  - Effectively isolates the expensive HTML5 layer from Flutter's widget reconciliation process.

### 📂 [widgets/tv_controls.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/tv_controls.dart)
- **Responsibility**: TV-optimized control overlay (used by both native and web TV builds).
- **Key Logic**:
  - `Stack` with a `GestureDetector` background so tapping anywhere toggles playback.
  - Large icons and labels for 10-foot UX.
  - Speed cycle button exclusive to TV mode.

### 📂 [widgets/tv_focus_button.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/tv_focus_button.dart)
- **Responsibility**: D-pad-compatible button with animated focus glow.
- **Key Logic**:
  - `FocusableActionDetector` drives the glow animation on focus.
  - `Shortcuts` maps `LogicalKeyboardKey.select` and `enter` → `ActivateIntent`.
  - Works identically with touch tap and hardware remote OK button.

### 📂 [widgets/phone_controls.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/phone_controls.dart)
- **Responsibility**: Mobile-optimized touch control overlay.
- **Key Logic**:
  - Portrait and Landscape layouts.
  - Bottom sheet speed selector, full-screen toggle, and seek bar.

### 📂 [widgets/seek_bar.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/seek_bar.dart)
- **Responsibility**: Video progress slider.
- **Key Logic**:
  - Has its own localized `BlocBuilder` listening only to `position`/`duration` so the rest of the UI is unaffected by high-frequency updates.
  - Formats time using `DurationExtension.toFormattedString()`.

### 📂 [widgets/play_pause_button.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/play_pause_button.dart)
- **Responsibility**: Animated play/pause icon toggle.

### 📂 [widgets/status_overlay.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/status_overlay.dart)
- **Responsibility**: Center-screen flash icon for play/pause feedback.
- **Key Logic**:
  - Shown for ~800 ms after any play/pause action, mimicking premium streaming apps.

### 📂 [widgets/double_tap_feedback.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/double_tap_feedback.dart)
- **Responsibility**: Mobile gesture seek feedback overlay.
- **Key Logic**:
  - Curved `BorderRadius` shape hugs the screen edge on the tapped side.
  - Automatically disabled on TV to avoid interfering with D-pad navigation.

### 📂 [widgets/speed_selector_bottom_sheet.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/speed_selector_bottom_sheet.dart)
- **Responsibility**: Mobile-only playback speed selector.
- **Key Logic**:
  - `DraggableScrollableSheet` works in both Portrait and Landscape without overflow.
  - Speed options defined from `AppConstants` for consistency.

---

## 4. Web & Platform Configuration

### 📂 [web/index.html](file:///d:/e_and/multi_platform_video_player/web/index.html)
- **Responsibility**: Web entry point.
- **Key Logic**:
  - Configures `canvasKitBaseUrl` for offline/file-protocol support.
  - Implements a pure CSS loading spinner for the initial TV boot.

### 📂 [assets/translations/](file:///d:/e_and/multi_platform_video_player/assets/translations/)
- **Responsibility**: Multi-language support (English/Arabic).
- **Key Logic**:
  - `en.json` and `ar.json` provide all UI strings, consumed via `AppStrings`.

---

## 5. Build & Deployment Scripts (`scripts/`)

| File | Purpose |
|---|---|
| `run_webos_hosted.ps1` | **Fast Dev**: Builds, patches, and launches on the webOS emulator using a local HTTP host (most reliable for dev). |
| `run_webos_packaged.ps1` | **Prod Test**: Builds, patches, and packages into a `.ipk` for real device installation. |
| `run_tizen_wgt.ps1` | **Tizen Dev**: Builds, patches, and installs the `.wgt` package on a Tizen generic emulator. |
| `encode_tv_sample.ps1` | **Media Prep**: Uses FFmpeg to convert assets to H.264 Baseline 720p (guaranteed compatibility for old TV decoders). |
| `patch_tv_js.js` | **Post-Build Fix**: Patches `flutter_bootstrap.js` for local CanvasKit + `file://` protocol, sets `base href="./"`, and prepares `media/` folder. |
| `repair_bootstrap.js` | **Safety**: Restore the bootstrap file if the patch process is interrupted. |

---

## 6. Tests (`test/`)

| File | Purpose |
|---|---|
| `test/features/video_player/cubit/video_player_cubit_test.dart` | 6 unit tests covering: initialization, play, pause, seek, speed change, and error state |
| `test/widget_test.dart` | Basic widget smoke test |
