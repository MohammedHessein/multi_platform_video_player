# Component Breakdown

Detailed breakdown of all UI components used in the project.

---

## TV Components

### 1. `TvFocusButton`
- **File**: `widgets/tv_focus_button.dart`
- **Purpose**: The universal D-pad-compatible button for TV UIs.
- **Key Features**:
  - `FocusableActionDetector` drives an animated "glow" ring when the button has focus.
  - `Shortcuts` maps `LogicalKeyboardKey.select` and `enter` → `ActivateIntent` so the remote's OK button triggers the same callback as a touch tap.
  - Works identically with both hardware remote and touch input.

### 2. `TvControls`
- **File**: `widgets/tv_controls.dart`
- **Purpose**: The TV-optimized full-screen control overlay.
- **Key Features**:
  - `Stack` with a full-screen `GestureDetector` background — tapping anywhere toggles playback.
  - Gradient background for readability over video.
  - Large icons, labels, and a speed-cycle button scaled for 10-foot viewing distance (speed button **hidden** when `PlatformUtils.isTizenNative` — native Tizen TV / emulator does not support `setPlaybackSpeed` reliably).
  - Used by both native TV and web TV builds.

### 3. `WebTvVideoLayout`
- **File**: `widgets/web_tv_video_layout.dart`
- **Purpose**: Full-screen scaffold for web/TV builds.
- **Key Features**:
  - Places `WebVideoSurface` (the HTML5 `<video>` element) as a full-screen background layer.
  - Overlays `TvControls` on top for D-pad interaction.
  - Only rendered when `PlatformUtils.isWebTv == true`.

### 4. `WebVideoSurface`
- **File**: `widgets/web_video_surface.dart`
- **Purpose**: Bridges the HTML5 `<video>` DOM element into the Flutter widget tree.
- **Key Features**:
  - **Rebuild Isolation**: Caches the `HtmlElementView` in `initState`. This ensures the video layer is never destroyed or re-created when the parent UI rebuilds, eliminating lag and flickering.
  - **Optimized Styles**: Uses `object-fit: fill` for better performance on webOS and removes expensive CSS hints like `will-change`.
  - **Aspect Ratio Sync**: Listens to the player and updates the `AspectRatio` wrapper only when the video's actual resolution changes.

---

## Mobile Components

### 5. `PhoneControls`
- **File**: `widgets/phone_controls.dart`
- **Purpose**: Mobile-optimized touch control overlay.
- **Key Features**:
  - Adapts layout for Portrait and Landscape orientations.
  - Includes seek bar, play/pause, speed selector trigger, and fullscreen toggle.
  - Bottom sheet speed selector for speed control.

### 6. `SeekBar` System
- **Files**: `widgets/tv_seek_bar.dart`, `widgets/phone_seek_bar.dart`, `widgets/tv_seek_bar_listenable.dart`
- **Purpose**: High-performance video progress tracking.
- **Key Features**:
  - **Platform Specialization**: `PhoneSeekBar` uses a standard interactive `Slider`, while `TvSeekBar` uses a non-interactive `LinearProgressIndicator` (optimized for remote control UX where seeking is done via D-pad clicks, not dragging).
  - **Performance**: `TvSeekBarListenable` uses `ValueListenableBuilder` to listen directly to the Cubit's position notifier, bypassing the entire Widget tree and Bloc state machine for 60fps updates on TV.
  - **Linear Traversal**: In TV mode, the seek bar is excluded from focus (`ExcludeFocus`) to ensure the D-pad only lands on actionable buttons.

### 7. `DoubleTapFeedback`
- **File**: `widgets/double_tap_feedback.dart`
- **Purpose**: Visual feedback for mobile double-tap seek gestures.
- **Key Features**:
  - Curved `BorderRadius` overlay that hugs the left or right screen edge.
  - Animated container with a directional seek icon (⏪ / ⏩).
  - Automatically disabled on TV builds.

### 8. `SpeedSelectorBottomSheet`
- **File**: `widgets/speed_selector_bottom_sheet.dart`
- **Purpose**: Mobile-only playback speed picker.
- **Key Features**:
  - `DraggableScrollableSheet` works correctly in both Portrait and Landscape without overflow.
  - Speed options sourced from `AppConstants` constants.
  - Auto-dismisses on selection.

---

## Shared Components

### 9. `PlayPauseButton`
- **File**: `widgets/play_pause_button.dart`
- **Purpose**: Animated icon that toggles between Play and Pause states.
- **Key Features**:
  - Smooth `AnimatedSwitcher` transition between icons.
  - Used inside both `TvControls` and `PhoneControls`.

### 10. `StatusOverlay`
- **File**: `widgets/status_overlay.dart`
- **Purpose**: Center-screen flash icon confirming play/pause.
- **Key Features**:
  - Appears for ~800 ms after any play/pause toggle.
  - `AnimatedOpacity` fade-out effect mimicking premium streaming app behavior.
  - Controlled by `_statusOverlayTimer` in the Cubit.

### 11. `VideoView`
- **File**: `widgets/video_view.dart`
- **Purpose**: Main view orchestrator — selects the correct layout based on platform.
- **Key Features**:
  - `isWebTv` → `WebTvVideoLayout` (HTML5 full-screen)
  - `isTV` (native) → `TvControls` over `AspectRatio`-wrapped video
  - `isPhone` → `PhoneControls` with double-tap gesture detection
  - Top-level `buildWhen` ignores `position`/`duration` to avoid full-tree rebuilds.
  - `Focus` widget intercepts all key events to wake the controls overlay on any remote button press.
