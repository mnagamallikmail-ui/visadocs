import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';

/// AnimatedHeroWords — rotating highlight word carousel
/// Used in the landing page hero headline.
/// Cycles through: Trusted → Certified → Independent → Accurate → Professional → Compliant
class AnimatedHeroWords extends StatefulWidget {
  final double textSize;
  final Color? textColor;
  final Color? pillColor;
  final Color? pillTextColor;

  const AnimatedHeroWords({
    super.key,
    this.textSize = 72,
    this.textColor,
    this.pillColor,
    this.pillTextColor,
  });

  @override
  State<AnimatedHeroWords> createState() => _AnimatedHeroWordsState();
}

class _AnimatedHeroWordsState extends State<AnimatedHeroWords>
    with SingleTickerProviderStateMixin {
  static const _words = [
    'Trusted',
    'Certified',
    'Independent',
    'Accurate',
    'Professional',
    'Compliant',
  ];

  int _currentIndex = 0;
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % _words.length;
          _visible = true;
        });
        _scheduleNext();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_currentIndex];
    final textColor = widget.pillTextColor ?? const Color(0xFF111827);

    final style = AppTypography.heroDisplayResponsive(
      widget.textSize * 18,
      color: textColor,
    ).copyWith(
      fontSize: widget.textSize,
      color: textColor,
      letterSpacing: -2.0,
      fontWeight: FontWeight.w700,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: _visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        curve: Curves.easeOutCubic,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            word,
            style: style,
          ),
        ),
      ),
    );
  }
}
