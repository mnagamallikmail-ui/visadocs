import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// HeroVideoWidget
///
/// An institutional-grade, zero-flash sequential video billboard.
///
/// Key Capabilities:
/// - Plays 8 videos strictly in numerical sequence (1.mp4 -> 8.mp4).
/// - Dual-controller architecture with 400ms cross-fade between Layer A and Layer B.
/// - Preloads video (N+1) in the background while video N is playing.
/// - Zero controls, zero progress bars, zero play buttons, zero white/loading flashes.
/// - Paused on initial frame during Phase 1 (0–3s), plays upon [playStory] signal.
/// - Notifies [onSequenceComplete] after Video 8 finishes and holds the final frame cleanly.
class HeroVideoWidget extends StatefulWidget {
  /// Ordered list of video asset paths (e.g. assets/videos/hero_story/1.mp4 .. 8.mp4)
  final List<String> videoAssets;

  /// Trigger to start playback (after initial 3.0s hero hold)
  final bool playStory;

  /// Callback fired when Video 8 finishes
  final VoidCallback? onSequenceComplete;

  /// Aspect ratio for the video billboard (defaults to 16/9)
  final double aspectRatio;

  const HeroVideoWidget({
    super.key,
    required this.videoAssets,
    this.playStory = false,
    this.onSequenceComplete,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<HeroVideoWidget> createState() => _HeroVideoWidgetState();
}

class _HeroVideoWidgetState extends State<HeroVideoWidget> {
  int _currentIndex = 0;

  // Dual-controller buffer to ensure zero-flash seamless transitions
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;

  bool _isAActive = true;
  bool _hasError = false;
  bool _transitioning = false;
  bool _sequenceFinished = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void didUpdateWidget(covariant HeroVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playStory && !oldWidget.playStory && !_sequenceFinished && !_isPlaying) {
      _startPlayback();
    }
  }

  Future<void> _initSequence() async {
    if (widget.videoAssets.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      // 1. Initialize Video 1 on Controller A
      final firstAsset = widget.videoAssets[0];
      final ctrlA = VideoPlayerController.asset(firstAsset);
      await ctrlA.initialize();
      await ctrlA.setVolume(0); // Autoplay policy / silent luxury presentation
      await ctrlA.setPlaybackSpeed(1.0);
      await ctrlA.seekTo(Duration.zero);

      if (!mounted) {
        ctrlA.dispose();
        return;
      }

      _controllerA = ctrlA;
      setState(() {});

      // 2. Preload Video 2 on Controller B immediately in the background
      if (widget.videoAssets.length > 1) {
        _preloadNextSlot(1, isSlotB: true);
      }

      // If playStory was already enabled at init, start now
      if (widget.playStory && !_sequenceFinished) {
        _startPlayback();
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _preloadNextSlot(int targetIndex, {required bool isSlotB}) async {
    if (targetIndex >= widget.videoAssets.length) return;

    try {
      final assetPath = widget.videoAssets[targetIndex];
      final nextCtrl = VideoPlayerController.asset(assetPath);
      await nextCtrl.initialize();
      await nextCtrl.setVolume(0);
      await nextCtrl.setPlaybackSpeed(1.0);
      await nextCtrl.seekTo(Duration.zero);

      if (!mounted) {
        nextCtrl.dispose();
        return;
      }

      if (isSlotB) {
        _controllerB?.dispose();
        _controllerB = nextCtrl;
      } else {
        _controllerA?.dispose();
        _controllerA = nextCtrl;
      }
    } catch (_) {
      // Background preload error safely handled on fallback
    }
  }

  Future<void> _startPlayback() async {
    if (_isPlaying || _sequenceFinished) return;
    _isPlaying = true;

    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (activeCtrl != null && activeCtrl.value.isInitialized) {
      activeCtrl.addListener(_videoTickListener);
      await activeCtrl.play();
    }
  }

  void _videoTickListener() {
    if (_transitioning || _sequenceFinished) return;

    final activeCtrl = _isAActive ? _controllerA : _controllerB;
    if (activeCtrl == null || !activeCtrl.value.isInitialized) return;

    final pos = activeCtrl.value.position;
    final dur = activeCtrl.value.duration;

    if (dur <= Duration.zero) return;

    // Check if this is the final video (Video 8)
    if (_currentIndex >= widget.videoAssets.length - 1) {
      if (pos >= dur || (!activeCtrl.value.isPlaying && pos > const Duration(seconds: 1))) {
        _sequenceFinished = true;
        _isPlaying = false;
        activeCtrl.removeListener(_videoTickListener);
        widget.onSequenceComplete?.call();
      }
      return;
    }

    // Crossfade 250ms before video reaches its end to prevent trailing black/freeze frames
    final remaining = dur - pos;
    if (remaining <= const Duration(milliseconds: 250) || pos >= dur) {
      _advanceToNext();
    }
  }

  Future<void> _advanceToNext() async {
    if (_transitioning || _sequenceFinished) return;
    if (_currentIndex >= widget.videoAssets.length - 1) return;

    _transitioning = true;
    final nextIndex = _currentIndex + 1;
    final currentCtrl = _isAActive ? _controllerA : _controllerB;
    final nextCtrlSlot = _isAActive ? _controllerB : _controllerA;

    // Safety fallback: ensure next controller is initialized
    VideoPlayerController readyCtrl;
    if (nextCtrlSlot != null && nextCtrlSlot.value.isInitialized) {
      readyCtrl = nextCtrlSlot;
    } else {
      try {
        final fallback = VideoPlayerController.asset(widget.videoAssets[nextIndex]);
        await fallback.initialize();
        await fallback.setVolume(0);
        await fallback.seekTo(Duration.zero);
        if (_isAActive) {
          _controllerB = fallback;
        } else {
          _controllerA = fallback;
        }
        readyCtrl = fallback;
      } catch (_) {
        _transitioning = false;
        return;
      }
    }

    await readyCtrl.setVolume(0);
    await readyCtrl.seekTo(Duration.zero);
    readyCtrl.addListener(_videoTickListener);
    await readyCtrl.play();

    // Trigger seamless 400ms cross-fade
    if (mounted) {
      setState(() {
        _isAActive = !_isAActive;
        _currentIndex = nextIndex;
      });
    }

    // Allow crossfade animation to settle
    await Future.delayed(const Duration(milliseconds: 400));

    // Pause old controller and detach its listener
    if (currentCtrl != null) {
      currentCtrl.removeListener(_videoTickListener);
      await currentCtrl.pause();
    }

    // Preload next-next video in the now-inactive slot
    final upcomingIndex = _currentIndex + 1;
    if (upcomingIndex < widget.videoAssets.length) {
      _preloadNextSlot(upcomingIndex, isSlotB: _isAActive);
    }

    _transitioning = false;
  }

  @override
  void dispose() {
    _controllerA?.removeListener(_videoTickListener);
    _controllerB?.removeListener(_videoTickListener);
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Midnight Navy
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0x33334155),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330F172A),
              blurRadius: 40,
              offset: Offset(0, 20),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Midnight Navy backdrop prevents any possible white background flash
              const ColoredBox(color: Color(0xFF0F172A)),

              // Video Layer A
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

              // Video Layer B
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

              // Subtle ambient institutional glass top reflection
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 48,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x1FFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),

              // Error or loading state fallback
              if (_hasError)
                const Center(
                  child: Text(
                    'Pro Valuer Asset Showcase',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
