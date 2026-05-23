# Technical Deep Dive

This document provides a deep technical analysis of the advanced solutions implemented in this project to solve complex multi-platform challenges.

---

## 1. The Android TV Focus System

### Why `FocusableActionDetector`?
Instead of using a simple `GestureDetector`, we use `FocusableActionDetector` in [tv_focus_button.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/tv_focus_button.dart).
- **The Problem**: Standard buttons in Flutter don't always show a visible focus state on TV, and mapping Remote "OK" buttons often requires boilerplate.
- **The Solution**:
  - `onShowFocusHighlight`: Triggers the "Glowing" animation when the D-pad moves focus to the button.
  - `shortcuts`: Maps `LogicalKeyboardKey.select` and `enter` to a single `ActivateIntent`.
  - `actions`: Links that `ActivateIntent` to the Cubit's `onTap` logic.
  - This allows the same button to work with **Touch** and **Hardware Remote** simultaneously.

---

## 2. Advanced Responsive Scaling (The 960×540 Rule)

### The Logical Resolution Challenge
- **Phone**: High pixel density, small logical width (360–411 dp).
- **TV**: A 1080p TV in Android is typically **960×540 logical pixels** (2× density).
- **The Solution**: In [app_constants.dart](file:///d:/e_and/multi_platform_video_player/lib/core/constants/app_constants.dart), we defined separate design sizes for each device class. `ScreenUtilInit` uses these ratios to scale icons and fonts. The Play button appears massive on TV (readable from 10 feet) but appropriately sized on a phone — using the same sp/w values throughout.

---

## 3. The State Machine: Auto-Hide Controls

### Timer Coordination in `VideoPlayerCubit`
The auto-hide feature is implemented as a proper state machine:
1. **Reset Pattern**: Every user action (`togglePlayPause`, `seek`, `changeSpeed`) calls `showControls()`.
2. **Race Condition Prevention**: `_controlsTimer?.cancel()` is called before starting a new timer — multiple rapid clicks never trigger overlapping hide events.
3. **Immersive Wake-up**: In [video_view.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/widgets/video_view.dart), a `Focus` widget's `onKeyEvent` detects any remote input and calls `showControls()`, instantly waking the overlay.

---

## 4. Performance: Granular UI Rebuilds

### The `buildWhen` Strategy
- **The Problem**: Video position updates every ~500 ms. Rebuilding the entire widget tree at that rate kills performance on low-end TV hardware.
- **The Solution**:
  - The main `BlocBuilder` in `video_view.dart` ignores `position` and `duration` field changes:
    ```dart
    buildWhen: (prev, curr) =>
        prev.copyWith(position: curr.position, duration: curr.duration) != curr;
    ```
  - The `SeekBar` has its **own localized `BlocBuilder`** that only rebuilds on position changes.
  - Result: the entire control layout (icons, modals, buttons) only rebuilds on structural state changes (play/pause, speed, visibility), while the seek bar stays silky smooth.

---

## 5. Premium Interaction: Double Tap to Seek

### Gesture Handling
- A custom `GestureDetector` in `video_view.dart` detects double taps on the left or right screen half.
- **Visual Feedback**: `DoubleTapFeedback` renders a transient curved overlay matching the screen edge, with an animated icon indicating direction.
- **TV Safety**: Automatically disabled on TV (`PlatformUtils.isTV`) to avoid D-pad interference.

---

## 6. Lifecycle Resilience

### `WidgetsBindingObserver`
In [video_player_cubit.dart](file:///d:/e_and/multi_platform_video_player/lib/features/video_player/cubit/video_player_cubit.dart):
- `didChangeAppLifecycleState` is overridden.
- On `AppLifecycleState.paused` (phone call, app switch), `player.pause()` is called immediately.
- Prevents the "Ghost Audio" bug — a common Play Store / App Store rejection reason.

---

## 7. Multi-TV Platform Strategy

### Platform Detection Architecture
In [platform_utils.dart](file:///d:/e_and/multi_platform_video_player/lib/core/utils/platform_utils.dart):

```
kIsWeb?            → TV mode  (Samsung Tizen .wgt / LG webOS .ipk)
Platform.isAndroid → MethodChannel → UiModeManager → TV or Phone
Platform.isMacOS   → TV mode  (Apple TV proxy)
Platform.isLinux   → TV mode  (flutter-tizen native .tpk)
                     isTizenNative = !kIsWeb && Platform.isLinux
Otherwise          → Phone mode
```

### Why This Works for All TV Platforms
- **Android TV**: Native `MethodChannel` → `UiModeManager.getCurrentModeType()`. The only runtime way to tell Android TV apart from an Android Phone inside the same APK.
- **Samsung Tizen (Web)**: App packaged as `.wgt` runs in Tizen's Chromium engine → `kIsWeb == true` → TV mode + `WebAppVideoPlayer`.
- **Samsung Tizen (Native)**: `flutter-tizen build tpk` compiles to a Linux-based native binary → `Platform.isLinux == true` → TV mode + `NativeAppVideoPlayer`.
- **LG webOS**: Packaged as `.ipk`, runs in webOS Chromium → `kIsWeb == true` → TV mode + `WebAppVideoPlayer`.
- **Apple TV**: No official tvOS support yet. macOS desktop proxies the TV layout. Keyboard arrows map directly to Siri Remote behavior.

---

## 8. Web TV Video Loading (HTML5 Backend)

### Problem: 90-Second Load Hang on Standard Web
The original `WebAppVideoPlayer._loadSource` only awaited `onLoadedMetadata.first`. On a standard dev server, the first URL candidate (`media/<file>`) returns 404. Because `loadedmetadata` never fires for a failed URL, the player silently hung for the full 90-second timeout before trying the next candidate.

### Fix 1: Protocol-Aware URL Prioritization
`assetUrlCandidates()` now inspects `Uri.base.scheme`:

| Protocol | First Candidate | Reason |
|---|---|---|
| `file://` | `media/<file>` | Packaged `.ipk`/`.wgt` — local TV folder |
| `http://` / `https://` | `assets/assets/<path>` | Flutter Web dev server / hosted build |

### Fix 2: Completer-Based Fast-Fail
`_loadSource` now races `onLoadedMetadata` vs `onError` using a `Completer`:

```dart
final completer = Completer<void>();
metaSub = _video.onLoadedMetadata.listen((_) => completer.complete());
errSub  = _video.onError.listen((_) => completer.completeError(...));
_video.src = url;
_video.load();
await completer.future.timeout(const Duration(seconds: 15));
```

A 404 or network error now rejects the Future in **milliseconds** (not 90 seconds), enabling near-instant failover to the next URL candidate. The timeout was also reduced from 90 s → **15 s**.

---

## 9. Smart TV Web Performance Optimizations

### Pressure Reduction (CPU/UI Thread)
- **Problem**: The HTML5 `timeupdate` event fires at a very high frequency on some TV browsers, causing excessive message channel traffic between the browser and Flutter.
- **Solution**: We removed the `timeupdate` listener and switched to a `500ms` periodic timer. This provides enough resolution for the seek bar while drastically reducing the CPU interrupt load.

### DOM Node Stability
- **Problem**: Re-rendering an `HtmlElementView` causes the underlying `<iframe>` or DOM node to be re-inserted, which leads to video flickering and high latency on webOS.
- **Solution**: The `WebVideoSurface` uses a `late final` widget variable to store the view once in `initState`. Even if the Flutter widget tree rebuilds, the engine sees the same object and keeps the DOM element intact.

### Engine Attribute Tuning
- **Preload**: Set to `none` to prevent the TV from saturating its network interface or memory during startup.
- **Object-Fit**: Switched to `fill` because `contain` often requires the browser to calculate letterboxing, which can be expensive on older TV hardware.
- **Layer Promotion**: Removed `will-change: transform` as it can force "tiling" on webOS Chromium versions, leading to memory exhaustion.

---

## 10. Overriding TV Spatial Focus Navigation

### The Spatial Algorithm Problem
Flutter's default D-pad navigation uses a **Spatial Algorithm** that calculates the physically nearest focusable widget. When buttons have different sizes (large Play button vs smaller Rewind/Forward), or a wide `Slider` sits in the layout, focus jumps unexpectedly or gets stuck.

### The Solution: Linear Focus Traversal
We override the D-pad arrows in `tv_controls.dart` and `video_view.dart`:
```dart
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.arrowLeft):  PreviousFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
  },
)
```
Combined with `ExcludeFocus` wrapping the `Slider` widget, this forces **strict linear traversal** — Rewind → Play/Pause → Forward — regardless of layout changes or button sizes.

---

## 11. Media Compatibility: The 720p Baseline Rule

### Why 720p Baseline?
- **Problem**: Modern 4K TVs often have weak HEVC/H.265 decoders in their "Web Widget" sandbox. A video that plays in the TV's native player might fail or lag inside a packaged web app.
- **The Solution**: The `scripts/encode_tv_sample.ps1` uses FFmpeg to force a specific profile:
  - **Codec**: `libx264`
  - **Profile**: `baseline` (removes B-frames for easier decoding)
  - **Resolution**: `1280x720` (perfect balance for TV hardware)
  - **Bitrate**: `2.5M`
  - This ensures the video renders smoothly even on older 2018/2019 Tizen/webOS models.
