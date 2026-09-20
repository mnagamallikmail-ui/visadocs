import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// HeroVideoWidget
///
/// An institutional-grade, zero-flash sequential video player with reading break support.
///
/// Key Capabilities:
/// - Plays 8 videos strictly in numerical sequence (1.mp4 -> 8.mp4).
/// - Completely unblurred, sharp, crisp 1080p full-bleed cinematic background (BoxFit.cover).
/// - Dual-controller architecture with 400ms cross-fade between Layer A and Layer B.
/// - Preloads only (N+1) in the background while video N is ready or playing.
/// - Controlled playback with [activeVideoIndex] and [isPlaying].
/// - Notifies [onVideoCompleted] when each video finishes so the parent can initiate reading breaks.
/// - When Video 8 completes, softly loops Video 8 continuously without restarting the sequence.
class HeroVideoWidget extends StatefulWidget {
  /// Ordered list of video asset paths (assets/videos/hero_story/1.mp4 .. 8.mp4)
  final List<String> videoAssets;

  /// The active video index to display/play (0 to 7)
  final int activeVideoIndex;

  /// Whether the active video is currently playing
  final bool isPlaying;

  /// Callback fired when the active video reaches its end
  final ValueChanged<int>? onVideoCompleted;

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
  // Dual-controller buffer to ensure zero-flash seamless transitions
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;

  int _loadedIndexA = 0;
  int _loadedIndexB = 1;
  bool _isAActive = true;

  bool _hasError = false;
  bool _transitioning = false;
  bool _activeListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _initInitialControllers();
  }

  @override
  void didUpdateWidget(covariant HeroVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If active video index changed, transition to the new video
    if (widget.activeVideoIndex != oldWidget.activeVideoIndex) {
      _switchToVideo(widget.activeVideoIndex);
    } else if (widget.isPlaying != oldWidget.isPlaying) {
      // If play/pause state changed
      if (widget.isPlaying) {
        _playActive();
      } else {
        _pauseActive();
      }
    }
  }

  Future<void> _initInitialControllers() async {
    if (widget.videoAssets.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      // 1. Initialize Video 1 on Controller A
      final firstAsset = widget.videoAssets[0];
      final ctrlA = VideoPlayerController.asset(firstAsset);
      await ctrlA.initialize();
      await ctrlA.setVolume(0); // Muted for browser autoplay compliance
      await ctrlA.setPlaybackSpeed(1.0);
      await ctrlA.seekTo(Duration.zero);

      if (!mounted) {
        ctrlA.dispose();
        return;
      }

      _controllerA = ctrlA;
      _loadedIndexA = 0;
      _isAActive = true;
      setState(() {});

      // 2. Preload Video 2 on Controller B immediately in the background
      if (widget.videoAssets.length > 1) {
        _preloadSlotB(1);
      }

      // If already asked to play at initialization
      if (widget.isPlaying) {
        _playActive();
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _preloadSlotA(int index) async {
    if (index >= widget.videoAssets.length) return;
    try {
      final ctrl = VideoPlayerController.asset(widget.videoAssets[index]);
      await ctrl.initialize();
      await ctrl.setVolume(0);
      await ctrl.setPlaybackSpeed(1.0);
      await ctrl.seekTo(Duration.zero);
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _controllerA?.dispose();
      _controllerA = ctrl;
      _loadedIndexA = index;
    } catch (_) {}
  }

  Future<void> _preloadSlotB(int index) async {
    if (index >= widget.videoAssets.length) return;
    try {
      final ctrl = VideoPlayerController.asset(widget.videoAssets[index]);
      await ctrl.initialize();
      await ctrl.setVolume(0);
      await ctrl.setPlaybackSpeed(1.0);
      await ctrl.seekTo(Duration.zero);
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _controllerB?.dispose();
      _controllerB = ctrl;
      _loadedIndexB = index;
    } catch (_) {}
  }

  Future<void> _switchToVideo(int newIndex) async {
    if (_transitioning) return;
    _transitioning = true;

    final targetIsSlotA = (_loadedIndexA == newIndex);
    final targetIsSlotB = (_loadedIndexB == newIndex);

    // Make sure target controller is ready
    if (!targetIsSlotA && !targetIsSlotB) {
      // Need on-the-fly load into whichever slot is inactive
      if (_isAActive) {
        await _preloadSlotB(newIndex);
      } else {
        await _preloadSlotA(newIndex);
      }
    }

    final newIsAActive = (_loadedIndexA == newIndex);
    final nextCtrl = newIsAActive ? _controllerA : _controllerB;
    final oldCtrl = _isAActive ? _controllerA : _controllerB;

    if (oldCtrl != null && _activeListenerAttached) {
      oldCtrl.removeListener(_videoTickListener);
      _activeListenerAttached = false;
      await oldCtrl.pause();
    }

    if (nextCtrl != null && nextCtrl.value.isInitialized) {
      await nextCtrl.seekTo(Duration.zero);
      await nextCtrl.setVolume(0);

      // If reaching Video 8, enable continuous soft loop on it
      if (newIndex >= widget.videoAssets.length - 1) {
        await nextCtrl.setLooping(true);
      }

      if (widget.isPlaying) {
        nextCtrl.addListener(_videoTickListener);
        _activeListenerAttached = true;
        await nextCtrl.play();
      }
    }

    if (mounted) {
      setState(() {
        _isAActive = newIsAActive;
      });
    }

    // Wait for 400ms crossfade to settle
    await Future.delayed(const Duration(milliseconds: 400));

    // Preload next upcoming video in the inactive slot
    final nextUpcomingIndex = newIndex + 1;
    if (nextUpcomingIndex < widget.videoAssets.length) {
      if (_isAActive) {
        _preloadSlotB(nextUpcomingIndex);
      } else {
        _preloadSlotA(nextUpcomingIndex);
      }
    }

    _transitioning = false;
  }

  Future<void> _playActive() async {
    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (activeCtrl != null && activeCtrl.value.isInitialized) {
      if (!_activeListenerAttached) {
        activeCtrl.addListener(_videoTickListener);
        _activeListenerAttached = true;
      }
      await activeCtrl.play();
    }
  }

  Future<void> _pauseActive() async {
    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (activeCtrl != null && activeCtrl.value.isInitialized) {
      if (_activeListenerAttached) {
        activeCtrl.removeListener(_videoTickListener);
        _activeListenerAttached = false;
      }
      await activeCtrl.pause();
    }
  }

  void _videoTickListener() {
    if (_transitioning) return;

    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (activeCtrl == null || !activeCtrl.value.isInitialized) return;

    final pos = activeCtrl.value.position;
    final dur = activeCtrl.value.duration;

    if (dur <= Duration.zero) return;

    // Check if video reached its end
    if (pos >= dur - const Duration(milliseconds: 150) ||
        (!activeCtrl.value.isPlaying && pos > const Duration(seconds: 1))) {
      // Video completed
      activeCtrl.removeListener(_videoTickListener);
      _activeListenerAttached = false;

      // If it's Video 8, let it loop softly
      if (widget.activeVideoIndex >= widget.videoAssets.length - 1) {
        activeCtrl.setLooping(true);
        if (!activeCtrl.value.isPlaying) activeCtrl.play();
      } else {
        activeCtrl.pause();
      }

      widget.onVideoCompleted?.call(widget.activeVideoIndex);
    }
  }

  @override
  void dispose() {
    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (_activeListenerAttached) {
      activeCtrl?.removeListener(_videoTickListener);
    }
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const ColoredBox(color: Color(0xFF080E1A));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid dark base to eliminate any possible white flashes
        const ColoredBox(color: Color(0xFF080E1A)),

        // Video Layer A (Sharp, Native 1080p, Zero Blur)
        AnimatedOpacity(
          opacity: _isAActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _controllerA != null && _controllerA!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controllerA!.value.size.width,
                    height: _controllerA!.value.size.height,
                    child: VideoPlayer(_controllerA!),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Video Layer B (Sharp, Native 1080p, Zero Blur)
        AnimatedOpacity(
          opacity: !_isAActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _controllerB != null && _controllerB!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controllerB!.value.size.width,
                    height: _controllerB!.value.size.height,
                    child: VideoPlayer(_controllerB!),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
