import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// HeroVideoWidget
///
/// Autoplaying, muted, looping MP4 hero animation.
/// Replaces the hand-coded valuation dashboard mockup in [HeroSection].
///
/// Behaviour:
/// - Initialises [VideoPlayerController] from bundled asset once in [initState].
/// - Sets volume to 0 (muted) and loops before calling [play].
/// - Shows a styled placeholder while the controller is initialising.
/// - Shows the same placeholder if an error occurs — no technical message
///   is ever surfaced to the end user.
/// - Disposes the controller cleanly in [dispose].
/// - Carries the same flutter_animate entry animation as the old _rightVisual().
class HeroVideoWidget extends StatefulWidget {
  /// Asset path of the MP4, relative to the project root (registered in pubspec).
  final String assetPath;

  /// Fixed height for the video container. Matches the old dashboard height.
  final double height;

  const HeroVideoWidget({
    super.key,
    this.assetPath = 'assets/videos/hero_animation.mp4',
    this.height = 480,
  });

  @override
  State<HeroVideoWidget> createState() => _HeroVideoWidgetState();
}

class _HeroVideoWidgetState extends State<HeroVideoWidget> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.asset(widget.assetPath);

    try {
      await _controller.initialize();

      // Must mute before play — browsers block unmuted autoplay.
      await _controller.setVolume(0);
      await _controller.setLooping(true);
      await _controller.play();

      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      // Silently swallow the error; _hasError triggers the fallback UI.
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _buildAnimatedShell(
      child: _buildContent(),
    );
  }

  /// Wraps the video shell in the exact same flutter_animate entry animation
  /// that the old _rightVisual() used — preserving identical hero timing.
  Widget _buildAnimatedShell({required Widget child}) {
    return child
        .animate(delay: 600.ms)
        .fadeIn(duration: 700.ms)
        .slideX(begin: 0.08, end: 0, duration: 700.ms);
  }

  Widget _buildContent() {
    // Error state — styled fallback, no user-facing technical message.
    if (_hasError) return _buildPlaceholder();

    // Loading state — placeholder matches container styling exactly.
    if (!_initialized) return _buildPlaceholder();

    // Video ready.
    return _buildVideoContainer();
  }

  // ── Video container ──────────────────────────────────────────────────────

  Widget _buildVideoContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl), // 24px
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.subtle,
        ),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  // ── Placeholder ──────────────────────────────────────────────────────────

  /// Minimal placeholder — same card aesthetics as the old dashboard mockup.
  /// No spinner, no text, no error message — just the branded container shape.
  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.subtle,
      ),
    );
  }
}
