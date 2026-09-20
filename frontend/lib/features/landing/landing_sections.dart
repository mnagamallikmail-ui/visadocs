import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_components.dart';
import '../../theme/app_spacing.dart';
import 'animated_hero_words.dart';
import 'landing_theme.dart';
import 'widgets/hero_video_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING HEADER — Apple / Linear Minimalist Floating Navigation
// ═══════════════════════════════════════════════════════════════════════════════

class LandingHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isScrolled;
  final Future<void> Function(String) launchWhatsApp;
  final VoidCallback? onMenuTap;

  bool get isTransparent => !isScrolled;

  const LandingHeader({
    super.key,
    required this.isDesktop,
    required this.isScrolled,
    required this.launchWhatsApp,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 12 : 6,
          sigmaY: isScrolled ? 12 : 6,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
            vertical: isScrolled ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: isScrolled
                ? LandingTheme.glassWhiteDense
                : LandingTheme.primaryBg.withValues(alpha: 0.94),
            border: Border(
              bottom: BorderSide(
                color: isScrolled
                    ? LandingTheme.hairlineBorder
                    : LandingTheme.hairlineBorder.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            boxShadow: isScrolled ? LandingTheme.glassShadow : const [],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _brandLogo(),
                if (isDesktop) ...[
                  Row(
                    children: [
                      _navLink('Services'),
                      const SizedBox(width: 36),
                      _navLink('Empanelment'),
                      const SizedBox(width: 36),
                      _navLink('Who We Serve'),
                    ],
                  ),
                  Row(
                    children: [
                      _pillButton(
                        label: 'Client Login',
                        isPrimary: false,
                        onTap: () => context.go('/login'),
                      ),
                      const SizedBox(width: 12),
                      _pillButton(
                        label: 'Consult Now',
                        isPrimary: true,
                        onTap: () => launchWhatsApp(
                          'Hello Provaluer, I would like to consult with your valuation team.',
                        ),
                      ),
                    ],
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.menu, color: LandingTheme.charcoal, size: 22),
                    onPressed: onMenuTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandLogo() {
    return AppComponents.logo(
      fontSize: 18,
      darkMode: false,
      overrideWordmark: LandingTheme.charcoal,
      overrideAccent: LandingTheme.primaryAccent,
    );
  }

  Widget _navLink(String text) {
    return _HeaderNavLink(text: text);
  }

  Widget _pillButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return _HeaderButton(
      label: label,
      isPrimary: isPrimary,
      onTap: onTap,
    );
  }
}

class _HeaderNavLink extends StatefulWidget {
  final String text;
  const _HeaderNavLink({required this.text});

  @override
  State<_HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<_HeaderNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 140),
        style: LandingTheme.bodySmMedium.copyWith(
          color: _hovered ? LandingTheme.primaryAccent : LandingTheme.textMuted,
          fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
        ),
        child: Text(widget.text),
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered ? LandingTheme.primaryAccent : LandingTheme.charcoal)
                : (_hovered ? LandingTheme.softBgTint : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _hovered
                        ? LandingTheme.primaryAccent.withValues(alpha: 0.3)
                        : LandingTheme.hairlineBorder,
                    width: 1.0,
                  ),
            boxShadow: widget.isPrimary ? LandingTheme.buttonShadow : const [],
          ),
          child: Text(
            widget.label,
            style: LandingTheme.button.copyWith(
              color: widget.isPrimary ? Colors.white : LandingTheme.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE MENU DRAWER — Quiet Architectural Drawer
// ═══════════════════════════════════════════════════════════════════════════════

class MobileMenuDrawer extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const MobileMenuDrawer({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: LandingTheme.primaryBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppComponents.logo(
                    fontSize: 18,
                    darkMode: false,
                    overrideWordmark: LandingTheme.charcoal,
                    overrideAccent: LandingTheme.charcoal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: LandingTheme.charcoal, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(color: LandingTheme.hairlineBorder, height: 1),
              const SizedBox(height: AppSpacing.xl),
              _menuItem('Services'),
              _menuItem('Empanelment'),
              _menuItem('Who We Serve'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: LandingTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LandingTheme.hairlineBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Client Login',
                      style: LandingTheme.button.copyWith(color: LandingTheme.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    launchWhatsApp(
                      'Hello Provaluer, I would like to consult with your valuation team.',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: LandingTheme.charcoal,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: LandingTheme.buttonShadow,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Consult Now',
                      style: LandingTheme.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          text,
          style: LandingTheme.cardTitle.copyWith(fontSize: 15.5),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO SECTION — Architectural Whitespace & Pure Editorial Centerpiece
// ═══════════════════════════════════════════════════════════════════════════════

class HeroSection extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;

  static const _videoAssets = [
    'assets/videos/hero_animation.mp4',
    'assets/videos/Create_a_premium_animated_hero.mp4',
  ];

  const HeroSection({
    super.key,
    required this.isDesktop,
    required this.launchWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 768 && w < 1024;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.only(
        top: isDesktop ? 96 : 80,
        bottom: isDesktop ? 88 : 60,
        left: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        right: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FloatingAmbientGlow(
            width: 750,
            height: 480,
            opacity: 0.07,
            alignment: Alignment.topRight,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 44, child: _leftContent(context, w)),
                        const SizedBox(width: 44),
                        const Expanded(
                          flex: 56,
                          child: HeroVideoWidget(
                            videoAssets: _videoAssets,
                            height: 540,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _leftContent(context, w),
                        SizedBox(height: isTablet ? 40 : 28),
                        HeroVideoWidget(
                          videoAssets: _videoAssets,
                          height: isTablet ? 440 : 300,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftContent(BuildContext context, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Editorial Eyebrow Tag
        const LuxuryEyebrowBadge(text: 'Institutional Asset Valuation & Advisory'),

        const SizedBox(height: 24),

        // Dominant Focal Point: Headline line 1 & 2
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          children: [
            Text(
              'Property',
              style: LandingTheme.heroHeading(w),
            ),
            GradientText(
              'Valuation',
              style: LandingTheme.heroHeading(w),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              'for',
              style: LandingTheme.heroHeading(w),
            ),
            AnimatedHeroWords(
              textSize: w >= 1280
                  ? 66
                  : w >= 1024
                      ? 54
                      : w >= 768
                          ? 44
                          : w >= 480
                              ? 34
                              : 29,
              pillColor: Colors.transparent,
              pillTextColor: LandingTheme.primaryAccent,
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Subtitle with high readability
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'IBBI registered valuation, chartered engineering certification, and risk advisory '
            'engineered for leading banks, financial consortiums, and public enterprises.',
            style: LandingTheme.bodyLg,
          ),
        ),

        const SizedBox(height: 40),

        // CTA buttons (Razor-sharp, Apple/Linear style)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HeroCtaButton(
              isPrimary: true,
              label: 'Request Consultation',
              icon: Icons.arrow_forward_rounded,
              onTap: () => launchWhatsApp(
                'Hello Provaluer, I am seeking a valuation consultation for my property/asset.',
              ),
            ),
            _HeroCtaButton(
              isPrimary: false,
              label: 'Client Login',
              icon: Icons.login_rounded,
              onTap: () => context.go('/login'),
            ),
          ],
        ),

        const SizedBox(height: 44),

        // Institutional Credential Marks
        Wrap(
          spacing: 32,
          runSpacing: 10,
          children: [
            _trustMark('IBBI Registered Valuers'),
            _trustMark('Empanelled with Reputed Banks'),
            _trustMark('Institutional Grade Accuracy'),
          ],
        ),
      ],
    );
  }

  Widget _trustMark(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: LandingTheme.primaryAccent,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: LandingTheme.bodySmMedium.copyWith(
              color: LandingTheme.secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _HeroCtaButton extends StatefulWidget {
  final bool isPrimary;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroCtaButton({
    required this.isPrimary,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeroCtaButton> createState() => _HeroCtaButtonState();
}

class _HeroCtaButtonState extends State<_HeroCtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered ? LandingTheme.primaryAccent : LandingTheme.charcoal)
                : (_hovered ? LandingTheme.softBgTint : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _hovered
                        ? LandingTheme.primaryAccent.withValues(alpha: 0.3)
                        : LandingTheme.hairlineBorder,
                    width: 1.0,
                  ),
            boxShadow: widget.isPrimary ? LandingTheme.buttonShadow : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: LandingTheme.button.copyWith(
                  color: widget.isPrimary ? Colors.white : LandingTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.icon,
                color: widget.isPrimary ? Colors.white : LandingTheme.textPrimary,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRUST BAR — Understated Typographic Empanelment Row (McKinsey / Stripe Style)
// ═══════════════════════════════════════════════════════════════════════════════

class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 36,
        horizontal: AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: LandingTheme.secondaryBg,
        border: Border.symmetric(
          horizontal: BorderSide(color: LandingTheme.hairlineBorder, width: 1.0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'EMPANELLED WITH LEADING SCHEDULED COMMERCIAL BANKS',
              style: LandingTheme.eyebrow,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _bankItem('State Bank of India'),
                _bullet(),
                _bankItem('Union Bank of India'),
                _bullet(),
                _bankItem('Punjab National Bank'),
                _bullet(),
                _bankItem('Central Bank of India'),
                _bullet(),
                _bankItem('Axis Bank'),
                _bullet(),
                _bankItem('Canara Bank'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankItem(String name) => Text(
        name,
        style: LandingTheme.bodySmMedium.copyWith(
          fontSize: 13.5,
          color: LandingTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _bullet() => const Text(
        '·',
        style: TextStyle(
          color: LandingTheme.primaryAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICES GRID — Architectural Grid of Core Practice Areas
// ═══════════════════════════════════════════════════════════════════════════════

class ServicesGrid extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final Future<void> Function(String) launchWhatsApp;

  const ServicesGrid({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.launchWhatsApp,
  });

  static const _services = [
    [
      'Land & Building Valuation',
      'Statutory, balance sheet, mortgage lending, and NCLT transactional valuation under IBBI mandate.',
      'Hello Provaluer, I would like to request Land & Building Valuation details.',
    ],
    [
      'Plant & Machinery Valuation',
      'Technical assessment of industrial installations, fabrication units, and automated manufacturing lines.',
      'Hello Provaluer, I would like to request Plant & Machinery Valuation details.',
    ],
    [
      'Securities & Financial Assets',
      'Corporate valuation for capital restructuring, mergers, share transfers, and regulatory compliance.',
      'Hello Provaluer, I would like to request Securities & Financial Asset Valuation details.',
    ],
    [
      'Net Worth Certificates',
      'Audited financial documentation for statutory visa filings, institutional guarantees, and liquidity proof.',
      'Hello Provaluer, I would like to request a Net Worth Certificate evaluation.',
    ],
    [
      'Chartered Engineer Services',
      'Technical certification for customs clearance, EPCG export schemes, and plant life assessment.',
      'Hello Provaluer, I would like to request Chartered Engineer certification services.',
    ],
    [
      'Lenders Independent Engineer',
      'Independent technical review, project milestone monitoring, and fund drawdown verification for banks.',
      'Hello Provaluer, I would like to request Lenders Independent Engineer (LIE) services.',
    ],
    [
      'Cost Vetting',
      'Detailed audit of civil construction expenditure, BOQ verification, and variance control analysis.',
      'Hello Provaluer, I would like to request Cost Vetting services.',
    ],
    [
      'Contractors Bill Ratification',
      'Third-party milestone sign-off, workmanship certification, and contractor billing ratification.',
      'Hello Provaluer, I would like to request Contractor Bill Ratification services.',
    ],
  ];

  static const _cardIcons = [
    Icons.apartment_rounded,
    Icons.precision_manufacturing_rounded,
    Icons.trending_up_rounded,
    Icons.description_rounded,
    Icons.engineering_rounded,
    Icons.account_balance_rounded,
    Icons.receipt_long_rounded,
    Icons.fact_check_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);
    final w = MediaQuery.of(context).size.width;

    return Container(
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LuxuryEyebrowBadge(text: 'Core Practice Areas'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Institutional Engineering\n& ',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Valuation Services',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isDesktop ? 0.92 : (isTablet ? 1.35 : 1.45),
                ),
                itemCount: _services.length,
                itemBuilder: (_, i) => _ServiceCard(
                  title: _services[i][0],
                  description: _services[i][1],
                  message: _services[i][2],
                  icon: _cardIcons[i],
                  launchWhatsApp: launchWhatsApp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String title, description, message;
  final IconData icon;
  final Future<void> Function(String) launchWhatsApp;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.message,
    required this.icon,
    required this.launchWhatsApp,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.launchWhatsApp(widget.message),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: LandingTheme.primaryBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? LandingTheme.primaryAccent.withValues(alpha: 0.35)
                  : LandingTheme.hairlineBorder,
              width: 1.0,
            ),
            boxShadow: _hovered
                ? LandingTheme.hoverShadow
                : LandingTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                color: _hovered ? LandingTheme.primaryAccent : LandingTheme.charcoal,
                size: 22,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: LandingTheme.cardTitle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      style: LandingTheme.bodySm,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get Enquiry',
                    style: LandingTheme.bodySmMedium.copyWith(
                      color: _hovered
                          ? LandingTheme.primaryAccent
                          : LandingTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: _hovered
                        ? LandingTheme.primaryAccent
                        : LandingTheme.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHY CHOOSE US — Institutional Rigor & Regulatory Governance
// ═══════════════════════════════════════════════════════════════════════════════

class WhyChooseUsSection extends StatelessWidget {
  final bool isDesktop;
  const WhyChooseUsSection({super.key, required this.isDesktop});

  static const _reasons = [
    [
      Icons.verified_outlined,
      'IBBI Registered',
      'Valuers registered under Insolvency and Bankruptcy Board of India mandate across asset categories.',
    ],
    [
      Icons.account_balance_outlined,
      'Bank Empanelled',
      'Active empanelment with public sector banks, private lenders, and NBFC consortiums.',
    ],
    [
      Icons.speed_outlined,
      'Disciplined Turnaround',
      '24-48 hour turnaround on standardized appraisal files with strict milestone checkpoints.',
    ],
    [
      Icons.gavel_outlined,
      'Statutory Compliance',
      'Full compliance with SEBI, RBI Master Directions, Companies Act, and Customs mandates.',
    ],
    [
      Icons.support_agent_outlined,
      'Chartered Engineers',
      'Senior valuation practice led by chartered engineers with decade-plus technical authority.',
    ],
    [
      Icons.star_outline_rounded,
      'Dual-Layer Verification',
      'Systematic quality assurance protocol ensuring institutional-grade evidentiary standards.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LuxuryEyebrowBadge(text: 'Institutional Governance'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Engineered for Banks, Built for\n',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Institutional Scrutiny',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isDesktop ? 1.8 : 3.2,
                ),
                itemCount: _reasons.length,
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: LandingTheme.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LandingTheme.hairlineBorder,
                      width: 1.0,
                    ),
                    boxShadow: LandingTheme.subtleShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _reasons[i][0] as IconData,
                        color: LandingTheme.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _reasons[i][1] as String,
                              style: LandingTheme.cardTitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _reasons[i][2] as String,
                              style: LandingTheme.bodySm,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// VALUATION WORKFLOW — 4-Stage Valuation Lifecycle
// ═══════════════════════════════════════════════════════════════════════════════

class ValuationWorkflowSection extends StatelessWidget {
  final bool isDesktop;
  const ValuationWorkflowSection({super.key, required this.isDesktop});

  static const _steps = [
    [
      '01',
      'Submit Request',
      'Upload asset documents and cadastral records via our secure client portal or direct advisory desk.',
    ],
    [
      '02',
      'Site Inspection',
      'Registered valuer conducts rigorous on-site measurements, structural checks, and physical audit.',
    ],
    [
      '03',
      'Analytical Appraisal',
      'Data reconciled against government registries, circle rates, and discounted cash-flow models.',
    ],
    [
      '04',
      'Sign-Off & Delivery',
      'Institutional report digitally signed under IBBI seal and dispatched directly to your lender.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LuxuryEyebrowBadge(text: 'Execution Methodology'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Rigorous 4-Stage ',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Valuation Lifecycle',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    _steps.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < _steps.length - 1 ? 32 : 0),
                        child: _WorkflowStep(
                          number: _steps[i][0],
                          title: _steps[i][1],
                          description: _steps[i][2],
                          isLast: i == _steps.length - 1,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(
                    _steps.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _WorkflowStep(
                        number: _steps[i][0],
                        title: _steps[i][1],
                        description: _steps[i][2],
                        isLast: i == _steps.length - 1,
                      ),
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

class _WorkflowStep extends StatelessWidget {
  final String number, title, description;
  final bool isLast;

  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: LandingTheme.cardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LandingTheme.primaryAccent,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 1,
                  color: LandingTheme.hairlineBorder,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: LandingTheme.cardTitle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: LandingTheme.bodySm,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHO WE SERVE — Specialized Practice Across Critical Sectors
// ═══════════════════════════════════════════════════════════════════════════════

class WhoWeServeSection extends StatelessWidget {
  final bool isDesktop;
  const WhoWeServeSection({super.key, required this.isDesktop});

  static const _groups = [
    [
      'Banks & Financial Institutions',
      'Providing technical asset appraisals, LIE audits, and bad-debt valuation backing empanelments.',
      Icons.account_balance_rounded,
    ],
    [
      'Corporates & Businesses',
      'Assisting in statutory audit valuations, mergers/acquisitions, restructuring, and commercial due diligence.',
      Icons.business_rounded,
    ],
    [
      'Manufacturing & Industries',
      'Valuation of factory premises, machinery life, asset capitalization, and EPCG licensing compliance.',
      Icons.precision_manufacturing_rounded,
    ],
    [
      'NBFCs & Fintechs',
      'Collateral verification, digital lending support, and property risk assessment for modern lenders.',
      Icons.credit_card_rounded,
    ],
    [
      'Government & Public Sector',
      'Government scheme valuations, EPCG compliance reports, and public sector asset assessments.',
      Icons.gavel_rounded,
    ],
    [
      'Individuals & HNIs',
      'Personal property valuations for loans, insurance, estate planning, and net worth certifications.',
      Icons.person_rounded,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LuxuryEyebrowBadge(text: 'Sector Coverage'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Specialized Practice Across\n',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Critical Sectors',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isDesktop ? 1.8 : 3.2,
                ),
                itemCount: _groups.length,
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: LandingTheme.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LandingTheme.hairlineBorder,
                      width: 1.0,
                    ),
                    boxShadow: LandingTheme.subtleShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _groups[i][2] as IconData,
                        color: LandingTheme.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _groups[i][0] as String,
                              style: LandingTheme.cardTitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _groups[i][1] as String,
                              style: LandingTheme.bodySm,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// STATS SECTION — Clean Architectural Metrics Band
// ═══════════════════════════════════════════════════════════════════════════════

class StatsSection extends StatelessWidget {
  final bool isDesktop;
  const StatsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final stats = [
      const _StatItem(customValue: 'Several Thousands of', label: 'Reports Delivered'),
      const _StatItem(customValue: 'Empanelled with', label: 'Reputed Banking Partners'),
      const _StatItem(value: '10+', label: 'Years of Experience'),
      const _StatItem(value: '100%', label: 'Client Satisfaction'),
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 85,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FloatingAmbientGlow(
            width: 650,
            height: 280,
            opacity: 0.05,
            alignment: Alignment.center,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 48 : 36,
                  horizontal: isDesktop ? 48 : 24,
                ),
                decoration: BoxDecoration(
                  color: LandingTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LandingTheme.hairlineBorder, width: 1.0),
                  boxShadow: LandingTheme.subtleShadow,
                ),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _interleaveWithDividers(stats),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(child: stats[0]),
                              Container(width: 1, height: 60, color: LandingTheme.hairlineBorder),
                              Expanded(child: stats[1]),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(color: LandingTheme.hairlineBorder, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(child: stats[2]),
                              Container(width: 1, height: 60, color: LandingTheme.hairlineBorder),
                              Expanded(child: stats[3]),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _interleaveWithDividers(List<Widget> items) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(Expanded(child: items[i]));
      if (i < items.length - 1) {
        result.add(Container(
          width: 1,
          height: 64,
          color: LandingTheme.hairlineBorder,
        ));
      }
    }
    return result;
  }
}

class _StatItem extends StatelessWidget {
  final String? value;
  final String? customValue;
  final String label;

  const _StatItem({
    this.value,
    this.customValue,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = customValue != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCustom)
          GradientText(
            value!,
            style: LandingTheme.statNumeral.copyWith(
              fontSize: 48,
              letterSpacing: -2.0,
            ),
          )
        else
          Text(
            customValue!,
            style: LandingTheme.statNumeral.copyWith(
              fontSize: customValue!.length > 12 ? 22 : 48,
              letterSpacing: customValue!.length > 12 ? -0.4 : -2.0,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 10),
        Text(
          label,
          style: LandingTheme.bodySmMedium.copyWith(
            color: LandingTheme.textMuted,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTIMONIALS — Verified Feedback from Financial Partners
// ═══════════════════════════════════════════════════════════════════════════════

class TestimonialsSection extends StatelessWidget {
  final bool isDesktop;
  const TestimonialsSection({super.key, required this.isDesktop});

  static const _testimonials = [
    [
      'The valuation report was delivered within 48 hours and accepted by the bank without any queries. Extremely professional team.',
      'Rajesh K.',
      'Home Loan Applicant',
      'State Bank of India',
    ],
    [
      'We needed a Chartered Engineer Certificate for customs clearance urgently. Pro Valuer delivered in record time with complete accuracy.',
      'Priya M.',
      'Import/Export Manager',
      'Manufacturing Co.',
    ],
    [
      'Their LIE reports for our infrastructure project were thorough and met all consortium bank requirements perfectly.',
      'Suresh R.',
      'CFO',
      'Infrastructure Pvt. Ltd.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LuxuryEyebrowBadge(text: 'Institutional Endorsements'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Verified Feedback from\n',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Financial Partners',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: isDesktop ? 1.35 : 2.2,
                ),
                itemCount: _testimonials.length,
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: LandingTheme.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LandingTheme.hairlineBorder,
                      width: 1.0,
                    ),
                    boxShadow: LandingTheme.subtleShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Padding(
                            padding: EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.star_rounded,
                              color: LandingTheme.primaryAccent,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: Text(
                          '"${_testimonials[i][0]}"',
                          style: LandingTheme.bodyMd.copyWith(
                            fontStyle: FontStyle.italic,
                            color: LandingTheme.textPrimary,
                            height: 1.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _testimonials[i][1],
                            style: LandingTheme.bodySmMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_testimonials[i][2]} · ${_testimonials[i][3]}',
                            style: LandingTheme.bodySm.copyWith(
                              fontSize: 12.5,
                              color: LandingTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// FAQ SECTION — Apple / Stripe Clean Hairline List
// ═══════════════════════════════════════════════════════════════════════════════

class FaqSection extends StatelessWidget {
  final bool isDesktop;
  const FaqSection({super.key, required this.isDesktop});

  static const _faqs = [
    [
      'What is an IBBI Registered Valuer?',
      'IBBI (Insolvency and Bankruptcy Board of India) registers qualified valuers who are authorized to provide valuation services for statutory and regulatory purposes including bank loans, NCLT proceedings, and government compliance.',
    ],
    [
      'How long does a property valuation take?',
      'Standard residential valuations take 24-48 hours after site inspection. Commercial and industrial valuations may take 3-5 working days depending on complexity.',
    ],
    [
      'Which banks accept your valuation reports?',
      'We are empanelled with banks including State Bank of India, Union Bank, Punjab National Bank, Axis Bank, Central Bank of India, and many more leading lenders.',
    ],
    [
      'Can you provide valuation for properties outside Hyderabad?',
      'Our primary service area is Hyderabad and Secunderabad. For properties in other locations within Telangana and Andhra Pradesh, please contact us to discuss coverage.',
    ],
    [
      'What documents are needed for a valuation?',
      'Typically: Sale/Title Deed, Approved Building Plan, Occupancy Certificate, Property Tax Receipts, and Electricity Bill. Specific documents vary by property type and purpose.',
    ],
    [
      'Do you provide Chartered Engineer certificates for EPCG?',
      'Yes, we provide Chartered Engineer Certificates for EPCG schemes, import/export, customs valuation, insurance, and government compliance requirements.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LuxuryEyebrowBadge(text: 'Operational Inquiries'),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Frequently Addressed\n',
                  style: LandingTheme.sectionTitleResponsive(w),
                  children: [
                    WidgetSpan(
                      child: GradientText(
                        'Operational Inquiries',
                        style: LandingTheme.sectionTitleResponsive(w),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              ..._faqs.map((faq) => _FaqItem(
                    question: faq[0],
                    answer: faq[1],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question, answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: LandingTheme.hairlineBorder, width: 1.0),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: LandingTheme.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: _expanded
                          ? LandingTheme.primaryAccent
                          : LandingTheme.charcoal,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    widget.answer,
                    style: LandingTheme.bodyMd.copyWith(
                      color: LandingTheme.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CTA BANNER — High-Trust Executive Conversion Section
// ═══════════════════════════════════════════════════════════════════════════════

class CtaBanner extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const CtaBanner({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: w >= 1200 ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 125,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FloatingAmbientGlow(
            width: 700,
            height: 400,
            opacity: 0.07,
            alignment: Alignment.center,
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: w >= 768 ? 72 : 48,
                  horizontal: w >= 768 ? 64 : 28,
                ),
                decoration: BoxDecoration(
                  color: LandingTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LandingTheme.hairlineBorder, width: 1.0),
                  boxShadow: LandingTheme.subtleShadow,
                ),
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Ready to ',
                        style: LandingTheme.sectionTitleResponsive(w),
                        children: [
                          WidgetSpan(
                            child: GradientText(
                              'Get Started?',
                              style: LandingTheme.sectionTitleResponsive(w),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'Connect with our expert valuation practice today.\nFast turnaround. Institutional-grade precision.',
                    style: LandingTheme.bodyLg,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _HeroCtaButton(
                      isPrimary: true,
                      label: 'Request Consultation',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => launchWhatsApp(
                        'Hello Provaluer, I would like to get started with a consultation.',
                      ),
                    ),
                    _HeroCtaButton(
                      isPrimary: false,
                      label: 'Client Login',
                      icon: Icons.login_rounded,
                      onTap: () => context.go('/login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
}
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOOTER — Soft White (#FAFAFA) Luxury Enterprise Footer
// ═══════════════════════════════════════════════════════════════════════════════

class LandingFooter extends StatelessWidget {
  final bool isDesktop;
  const LandingFooter({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) => Container(
        color: LandingTheme.secondaryBg,
        decoration: const BoxDecoration(
          color: LandingTheme.secondaryBg,
          border: Border(
            top: BorderSide(color: LandingTheme.hairlineBorder, width: 1.0),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
          vertical: 72,
        ),
        width: double.infinity,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _companyInfo(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _footerCol('Services', [
                            'Land & Building Valuation',
                            'Plant & Machinery',
                            'Net Worth Certificates',
                            'Chartered Engineer',
                            'LIE Reports',
                          ]),
                          const SizedBox(width: 80),
                          _footerCol('Company', [
                            'About Us',
                            'Empanelment',
                            'Who We Serve',
                            'Contact',
                            'Client Login',
                          ]),
                        ],
                      ),
                    ],
                  )
                else ...[
                  _companyInfo(),
                  const SizedBox(height: 36),
                ],
                const SizedBox(height: 56),
                const Divider(color: LandingTheme.hairlineBorder, height: 1),
                const SizedBox(height: 28),
                if (isDesktop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_copyright(), _tagline()],
                  )
                else ...[
                  _copyright(),
                  const SizedBox(height: 6),
                  _tagline(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _companyInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppComponents.logo(
            fontSize: 18,
            darkMode: false,
            overrideWordmark: LandingTheme.charcoal,
            overrideAccent: LandingTheme.charcoal,
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Provaluer OPC Private Limited\nAccurate Valuations. Professional Insights.\nTrusted Decisions.',
              style: LandingTheme.bodySm.copyWith(
                color: LandingTheme.textMuted,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _credentialChip('IBBI Registered Valuers'),
          const SizedBox(height: 8),
          _credentialChip('Hyderabad & Secunderabad'),
        ],
      );

  Widget _credentialChip(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: LandingTheme.primaryAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: LandingTheme.bodySm.copyWith(
              fontSize: 12,
              color: LandingTheme.textTertiary,
            ),
          ),
        ],
      );

  Widget _footerCol(String heading, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: LandingTheme.cardTitle.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  item,
                  style: LandingTheme.bodySm.copyWith(
                    color: LandingTheme.textMuted,
                  ),
                ),
              )),
        ],
      );

  Widget _copyright() => Text(
        '© 2026 Provaluer OPC Private Limited. All rights reserved.',
        style: LandingTheme.bodySm.copyWith(
          fontSize: 12,
          color: LandingTheme.textTertiary,
        ),
      );

  Widget _tagline() => Text(
        'Advisory Engineers & Registered Valuers',
        style: LandingTheme.bodySm.copyWith(
          fontSize: 12,
          color: LandingTheme.textTertiary,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEGACY COMPAT — HeroOverlayContent alias
// ═══════════════════════════════════════════════════════════════════════════════

class HeroOverlayContent extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;
  const HeroOverlayContent({
    super.key,
    required this.isDesktop,
    required this.launchWhatsApp,
  });

  @override
  Widget build(BuildContext context) => HeroSection(
        isDesktop: isDesktop,
        launchWhatsApp: launchWhatsApp,
      );
}
