import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// HeroVideoWidget — Production-Grade Cinematic Background Video Manager
///
/// Features:
/// - Strictly plays videos in sequence: 1.mp4 -> 2.mp4 -> 3.mp4 -> 4.mp4 -> 5.mp4 -> 7.mp4 -> 8.mp4
/// - Preloads ONLY current video + next upcoming video.
/// - Immediately disposes previous controllers upon transition to prevent GPU / hardware decoder exhaustion.
/// - Watchdog safety timer to prevent any video from hanging or freezing.
/// - Automatic error listener & recovery (auto-advances if video fails to load or play).
/// - Fallback playback completion detection.
/// - Returns SizedBox.shrink() when not playing (Reading Mode) so zero frozen frames or video elements appear.
class HeroVideoWidget extends StatefulWidget {
  final List<String> videoAssets;
  final int activeVideoIndex;
  final bool isPlaying;
  final void Function(int completedIndex)? onVideoCompleted;

  const HeroVideoWidget({
    super.key,
    required this.videoAssets,
    required this.activeVideoIndex,
    required this.isPlaying,
    this.onVideoCompleted,
  });

  @override
  State<HeroVideoWidget> createState() => _HeroVideoWidgetState();
}

class _HeroVideoWidgetState extends State<HeroVideoWidget> {
  VideoPlayerController? _currentController;
  int _currentLoadedIndex = -1;

  VideoPlayerController? _preloadedController;
  int _preloadedIndex = -1;

  Timer? _watchdogTimer;
  bool _isHandlingCompletion = false;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _setupInitialVideo();
  }

  @override
  void didUpdateWidget(covariant HeroVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.activeVideoIndex != oldWidget.activeVideoIndex) {
      _loadAndPlayVideo(widget.activeVideoIndex);
    } else if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _playCurrent();
      } else {
        _pauseCurrent();
      }
    }
  }

  Future<void> _setupInitialVideo() async {
    if (widget.videoAssets.isEmpty) return;
    await _loadAndPlayVideo(widget.activeVideoIndex);
  }

  Future<void> _loadAndPlayVideo(int targetIndex) async {
    if (targetIndex < 0 || targetIndex >= widget.videoAssets.length) return;
    if (_isSwitching) return;
    _isSwitching = true;
    _isHandlingCompletion = false;
    _watchdogTimer?.cancel();

    // 1. Immediately dispose old current controller to prevent memory/decoder leak
    final oldCtrl = _currentController;
    _currentController = null;
    if (oldCtrl != null) {
      try {
        oldCtrl.removeListener(_videoListener);
        await oldCtrl.pause();
        oldCtrl.dispose();
      } catch (_) {}
    }

    // 2. Check if the targetIndex was already preloaded
    VideoPlayerController? newCtrl;
    if (_preloadedIndex == targetIndex && _preloadedController != null && _preloadedController!.value.isInitialized) {
      newCtrl = _preloadedController;
      _preloadedController = null;
      _preloadedIndex = -1;
    } else {
      // Otherwise dispose any stale preloaded controller and load target
      final oldPreload = _preloadedController;
      _preloadedController = null;
      _preloadedIndex = -1;
      oldPreload?.dispose();

      try {
        final ctrl = VideoPlayerController.asset(widget.videoAssets[targetIndex]);
        await ctrl.initialize();
        await ctrl.setVolume(0);
        await ctrl.setPlaybackSpeed(1.0);
        await ctrl.setLooping(false);
        newCtrl = ctrl;
      } catch (_) {
        // Automatic recovery if initialization failed
        _isSwitching = false;
        _triggerCompletionFallback(targetIndex);
        return;
      }
    }

    if (!mounted) {
      newCtrl?.dispose();
      _isSwitching = false;
      return;
    }

    _currentController = newCtrl;
    _currentLoadedIndex = targetIndex;
    _currentController!.addListener(_videoListener);

    if (mounted) setState(() {});

    // 3. If widget is currently in playing state, start playback
    if (widget.isPlaying) {
      await _playCurrent();
    }

    _isSwitching = false;

    // 4. Preload ONLY the next video in the sequence
    final nextIndex = targetIndex + 1;
    if (nextIndex < widget.videoAssets.length) {
      _preloadNextVideo(nextIndex);
    }
  }

  Future<void> _preloadNextVideo(int nextIndex) async {
    // If already preloaded, skip
    if (_preloadedIndex == nextIndex && _preloadedController != null && _preloadedController!.value.isInitialized) {
      return;
    }

    final oldPreload = _preloadedController;
    _preloadedController = null;
    _preloadedIndex = -1;
    oldPreload?.dispose();

    try {
      final ctrl = VideoPlayerController.asset(widget.videoAssets[nextIndex]);
      await ctrl.initialize();
      await ctrl.setVolume(0);
      await ctrl.setPlaybackSpeed(1.0);
      await ctrl.setLooping(false);
      await ctrl.seekTo(Duration.zero);
      await ctrl.pause();

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      _preloadedController = ctrl;
      _preloadedIndex = nextIndex;
    } catch (_) {
      // Non-fatal, if preload fails, it will load on demand when targetIndex is requested
    }
  }

  Future<void> _playCurrent() async {
    final ctrl = _currentController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _watchdogTimer?.cancel();

    // Start playback
    try {
      await ctrl.seekTo(Duration.zero);
      await ctrl.setVolume(0);
      await ctrl.play();
    } catch (_) {
      _triggerCompletionFallback(_currentLoadedIndex);
      return;
    }

    // Arm Watchdog Safety Timer:
    // Guarantees no video can ever freeze or stall the story flow.
    final dur = ctrl.value.duration;
    final safetySeconds = dur.inSeconds > 0 ? dur.inSeconds + 3 : 16;
    _watchdogTimer = Timer(Duration(seconds: safetySeconds), () {
      if (!mounted || !_isHandlingCompletion) {
        _triggerCompletionFallback(_currentLoadedIndex);
      }
    });
  }

  Future<void> _pauseCurrent() async {
    _watchdogTimer?.cancel();
    final ctrl = _currentController;
    if (ctrl != null && ctrl.value.isInitialized) {
      try {
        await ctrl.pause();
      } catch (_) {}
    }
  }

  void _videoListener() {
    final ctrl = _currentController;
    if (ctrl == null || !ctrl.value.isInitialized || _isHandlingCompletion || _isSwitching) return;

    // 1. Error Listener & Automatic Recovery
    if (ctrl.value.hasError) {
      _triggerCompletionFallback(_currentLoadedIndex);
      return;
    }

    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur <= Duration.zero) return;

    // 2. Multi-point completion detection
    final bool reachedEnd = pos >= dur - const Duration(milliseconds: 250);
    final bool naturalEnd = pos > const Duration(seconds: 2) && !ctrl.value.isPlaying && pos >= dur - const Duration(seconds: 1);

    if (reachedEnd || naturalEnd) {
      _triggerCompletionFallback(_currentLoadedIndex);
    }
  }

  void _triggerCompletionFallback(int completedIndex) {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;
    _watchdogTimer?.cancel();

    final ctrl = _currentController;
    if (ctrl != null) {
      ctrl.removeListener(_videoListener);
      try {
        ctrl.pause();
      } catch (_) {}
    }

    if (mounted) {
      widget.onVideoCompleted?.call(completedIndex);
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _currentController?.removeListener(_videoListener);
    _currentController?.dispose();
    _preloadedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // During reading mode or if not playing: return SizedBox.shrink() so zero frozen frame appears
    if (!widget.isPlaying || _currentController == null || !_currentController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final ctrl = _currentController!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid dark base to eliminate any possible flicker
        const ColoredBox(color: Color(0xFF080E1A)),

        // Native 1080p unblurred sharp video
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width > 0 ? ctrl.value.size.width : 1920,
            height: ctrl.value.size.height > 0 ? ctrl.value.size.height : 1080,
            child: VideoPlayer(ctrl),
          ),
        ),
      ],
    );
  }
}
