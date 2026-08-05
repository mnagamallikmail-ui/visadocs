import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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
    final pillBg = widget.pillColor ?? AppColors.deepTeal;
    final pillText = widget.pillTextColor ?? AppColors.onDark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      opacity: _visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _visible ? Offset.zero : const Offset(0, 0.15),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            word,
            style: AppTypography.heroDisplayResponsive(
              widget.textSize * 18, // scale factor to pick appropriate size
              color: pillText,
            ).copyWith(fontSize: widget.textSize),
          ),
        ),
      ),
    );
  }
}
