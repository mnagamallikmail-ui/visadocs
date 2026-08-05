import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// HeroVideoWidget
///
/// Autoplaying, muted, sequentially cycling MP4 hero player.
///
/// Preloads the next video in sequence in the background, then performs
/// a smooth 250ms cross-fade transition between controllers to eliminate
/// flicker or blank screens.
class HeroVideoWidget extends StatefulWidget {
  /// Ordered list of video asset paths.
  final List<String> videoAssets;

  /// Height of the video player card.
  final double height;

  const HeroVideoWidget({
    super.key,
    required this.videoAssets,
    this.height = 480,
  });

  @override
  State<HeroVideoWidget> createState() => _HeroVideoWidgetState();
}

class _HeroVideoWidgetState extends State<HeroVideoWidget> {
  int _currentIndex = 0;

  // Double-controller setup to avoid web transition flicker
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;

  // Track active layer
  bool _isAActive = true;
  bool _initialized = false;
  bool _hasError = false;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _initFirstVideo();
  }

  Future<void> _initFirstVideo() async {
    if (widget.videoAssets.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final firstAsset = widget.videoAssets[_currentIndex];
    _controllerA = VideoPlayerController.asset(firstAsset);

    try {
      await _controllerA!.initialize();
      await _controllerA!.setVolume(0); // Muted
      await _controllerA!.setPlaybackSpeed(0.5);

      if (widget.videoAssets.length == 1) {
        await _controllerA!.setLooping(true); // Loop if single
      } else {
        _controllerA!.addListener(_videoListener);
      }

      await _controllerA!.play();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }

      // Preload the next video in sequence
      _preloadNextVideo();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _videoListener() {
    final activeController = _isAActive ? _controllerA : _controllerB;
    if (activeController == null || _transitioning) return;

    // Check if the current video reached its end
    if (activeController.value.isInitialized &&
        activeController.value.position >= activeController.value.duration) {
      _transitionToNext();
    }
  }

  Future<void> _preloadNextVideo() async {
    if (widget.videoAssets.length <= 1) return;

    final nextIndex = (_currentIndex + 1) % widget.videoAssets.length;
    final nextAsset = widget.videoAssets[nextIndex];
    final newController = VideoPlayerController.asset(nextAsset);

    try {
      await newController.initialize();
      await newController.setVolume(0); // Muted
      await newController.setPlaybackSpeed(0.5);

      if (mounted) {
        if (_isAActive) {
          _controllerB?.dispose();
          _controllerB = newController;
        } else {
          _controllerA?.dispose();
          _controllerA = newController;
        }
      }
    } catch (_) {
      // Silently catch preload failures; we will fallback/retry on swap if needed
    }
  }

  Future<void> _transitionToNext() async {
    if (_transitioning || widget.videoAssets.length <= 1) return;
    _transitioning = true;

    final nextController = _isAActive ? _controllerB : _controllerA;
    final currentController = _isAActive ? _controllerA : _controllerB;

    // Safety fallback: if background preloading hasn't completed or failed
    if (nextController == null || !nextController.value.isInitialized) {
      final nextIndex = (_currentIndex + 1) % widget.videoAssets.length;
      final nextAsset = widget.videoAssets[nextIndex];
      final fallbackController = VideoPlayerController.asset(nextAsset);

      try {
        await fallbackController.initialize();
        await fallbackController.setVolume(0);
        await fallbackController.setPlaybackSpeed(0.5);
        if (mounted) {
          if (_isAActive) {
            _controllerB = fallbackController;
          } else {
            _controllerA = fallbackController;
          }
        }
      } catch (_) {
        _transitioning = false;
        return; // Skip swap on error
      }
    }

    final readyNextController = _isAActive ? _controllerB! : _controllerA!;

    // Start playing the preloaded video immediately
    await readyNextController.play();
    readyNextController.addListener(_videoListener);

    // Cross-fade layers by flipping the active index state
    if (mounted) {
      setState(() {
        _isAActive = !_isAActive;
        _currentIndex = (_currentIndex + 1) % widget.videoAssets.length;
      });
    }

    // Wait for the 250ms cross-fade animation to complete
    await Future.delayed(const Duration(milliseconds: 250));

    // Pause and rewind the old video, and detach listener
    if (currentController != null) {
      currentController.removeListener(_videoListener);
      await currentController.pause();
      await currentController.seekTo(Duration.zero);
    }

    _transitioning = false;

    // Warm up the new next video
    _preloadNextVideo();
  }

  @override
  void dispose() {
    _controllerA?.removeListener(_videoListener);
    _controllerB?.removeListener(_videoListener);
    _controllerA?.dispose();
    _controllerB?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAnimatedShell(
      child: _buildContent(),
    );
  }

  Widget _buildAnimatedShell({required Widget child}) {
    return child
        .animate(delay: 600.ms)
        .fadeIn(duration: 700.ms)
        .slideX(begin: 0.08, end: 0, duration: 700.ms);
  }

  Widget _buildContent() {
    if (_hasError) return _buildPlaceholder();
    if (!_initialized) return _buildPlaceholder();
    return _buildVideoContainer();
  }

  Widget _buildVideoContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.stone.withValues(alpha: 0.6), width: 1.5),
        boxShadow: AppShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl - 1.5),
        child: AspectRatio(
          aspectRatio: (_controllerA != null && _controllerA!.value.isInitialized)
              ? _controllerA!.value.aspectRatio
              : 16 / 9,
          child: Stack(
            children: [
              // Layer A
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _isAActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _controllerA != null && _controllerA!.value.isInitialized
                      ? VideoPlayer(_controllerA!)
                      : const SizedBox.shrink(),
                ),
              ),
              // Layer B
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: !_isAActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _controllerB != null && _controllerB!.value.isInitialized
                      ? VideoPlayer(_controllerB!)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.stone.withValues(alpha: 0.6), width: 1.5),
          boxShadow: AppShadows.subtle,
        ),
      ),
    );
  }
}
