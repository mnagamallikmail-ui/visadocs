import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_components.dart';
import 'animated_hero_words.dart';
import 'widgets/hero_video_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class LandingHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isScrolled;
  final Future<void> Function(String) launchWhatsApp;
  final VoidCallback? onMenuTap;

  // Legacy compat — isTransparent maps to !isScrolled
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isScrolled
            ? AppColors.canvas.withOpacity(0.97)
            : AppColors.canvas,
        border: Border(
          bottom: BorderSide(
            color: isScrolled ? AppColors.hairline : Colors.transparent,
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: AppColors.deepTeal.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppComponents.logo(fontSize: 18),
            if (isDesktop) ...[
              Row(children: [
                _navLink('Services'),
                const SizedBox(width: AppSpacing.xxl),
                _navLink('Empanelment'),
                const SizedBox(width: AppSpacing.xxl),
                _navLink('Who We Serve'),
              ]),
              Row(children: [
                _pillButton(
                  label: 'Client Login',
                  isPrimary: false,
                  onTap: () => context.go('/login'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _pillButton(
                  label: 'Consult Now',
                  isPrimary: true,
                  onTap: () => launchWhatsApp(
                    'Hello Provaluer, I would like to consult with your valuation team.',
                  ),
                ),
              ]),
            ] else
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.ink),
                onPressed: onMenuTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String text) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: AppTypography.bodySmMedium(color: AppColors.textSecondary),
        ),
      );

  Widget _pillButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.deepTeal : Colors.transparent,
            borderRadius: AppRadius.brFull,
            border: isPrimary
                ? null
                : Border.all(color: AppColors.hairlineStrong),
          ),
          child: Text(
            label,
            style: AppTypography.buttonMd(
              color: isPrimary ? AppColors.onDark : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE MENU DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

class MobileMenuDrawer extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const MobileMenuDrawer({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppComponents.logo(fontSize: 18),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(color: AppColors.hairlineSoft),
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
                    padding: AppSpacing.buttonPadding,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.brFull,
                      border: Border.all(color: AppColors.hairlineStrong),
                    ),
                    alignment: Alignment.center,
                    child: Text('Client Login',
                        style: AppTypography.buttonMd(color: AppColors.ink)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    launchWhatsApp(
                        'Hello Provaluer, I would like to consult with your valuation team.');
                  },
                  child: Container(
                    padding: AppSpacing.buttonPadding,
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal,
                      borderRadius: AppRadius.brFull,
                    ),
                    alignment: Alignment.center,
                    child: Text('Consult Now',
                        style: AppTypography.buttonMd(color: AppColors.onDark)),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(text, style: AppTypography.bodyMd(color: AppColors.ink)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO SECTION — Editorial cream layout with animated words
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
    // Tablet: 768–1023px  |  Mobile: <768px
    final isTablet = w >= 768 && w < 1024;

    return Container(
      width: double.infinity,
      color: AppColors.canvas,
      padding: EdgeInsets.only(
        top: isDesktop ? 140 : 110,
        bottom: isDesktop ? 100 : 80,
        left: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        right: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              // ── Desktop: side-by-side, flex 55 / 45 ──────────────────────
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 55, child: _leftContent(context, w)),
                    const SizedBox(width: AppSpacing.xxl),
                    const Expanded(
                      flex: 45,
                      child: HeroVideoWidget(
                        videoAssets: _videoAssets,
                        height: 480,
                      ),
                    ),
                  ],
                )
              // ── Tablet / Mobile: stacked column ──────────────────────────
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _leftContent(context, w),
                    SizedBox(height: isTablet ? AppSpacing.xxl : AppSpacing.xl),
                    // Full-width video below hero text on tablet and mobile.
                    HeroVideoWidget(
                      videoAssets: _videoAssets,
                      height: isTablet ? 360 : 260,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _leftContent(BuildContext context, double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: AppRadius.brFull,
            border: Border.all(color: AppColors.deepTeal.withOpacity(0.2)),
          ),
          child: Text(
            'HYDERABAD & SECUNDERABAD',
            style: AppTypography.microUppercase(color: AppColors.deepTeal),
          ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0, duration: 500.ms),

        const SizedBox(height: AppSpacing.xxl),

        // Headline line 1
        Text(
          'Property Valuation\nfor',
          style: AppTypography.heroDisplayResponsive(w, color: AppColors.ink),
        ).animate(delay: 150.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),

        const SizedBox(height: 12),

        // Animated rotating words
        AnimatedHeroWords(
          textSize: w >= 1280
              ? 72
              : w >= 1024
                  ? 56
                  : w >= 768
                      ? 44
                      : w >= 480
                          ? 36
                          : 30,
          pillColor: AppColors.deepTeal,
          pillTextColor: AppColors.onDark,
        ).animate(delay: 400.ms).fadeIn(duration: 600.ms),

        const SizedBox(height: AppSpacing.xxl),

        // Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Property valuation, engineering certification and advisory services '
            'trusted by leading banks, financial institutions and enterprises.',
            style: AppTypography.bodyMd(color: AppColors.textMuted),
          ),
        ).animate(delay: 600.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),

        const SizedBox(height: AppSpacing.xxxl),

        // CTA buttons
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchWhatsApp(
                  'Hello Provaluer, I am seeking a valuation consultation for my property/asset.',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_outlined, color: AppColors.onDark, size: 16),
                      const SizedBox(width: 8),
                      Text('Request Consultation',
                          style: AppTypography.buttonMd(color: AppColors.onDark)),
                    ],
                  ),
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.hairlineStrong),
                  ),
                  child: Text('Client Login',
                      style: AppTypography.buttonMd(color: AppColors.ink)),
                ),
              ),
            ),
          ],
        ).animate(delay: 800.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),

        const SizedBox(height: AppSpacing.xxl),

        // Trust marks
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xs,
          children: [
            _trustMark('IBBI Registered Valuers'),
            _trustMark('20+ Bank Empanelments'),
            _trustMark('500+ Reports'),
          ],
        ).animate(delay: 1000.ms).fadeIn(duration: 600.ms),
      ],
    );
  }

  Widget _trustMark(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.successAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.caption(color: AppColors.textMuted)),
        ],
      );

}

// ═══════════════════════════════════════════════════════════════════════════════
// TRUST BAR
// ═══════════════════════════════════════════════════════════════════════════════

class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.hairline)),
      ),
      child: Center(
        child: Column(
          children: [
            Text('TRUSTED BY LEADING BANKING INSTITUTIONS',
                style: AppTypography.microUppercase(color: AppColors.stone),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: const [
                'State Bank of India',
                'Union Bank of India',
                'Punjab National Bank',
                'Central Bank of India',
                'Axis Bank',
                'Canara Bank',
              ].map(_bankChip).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bankChip(String name) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.brFull,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(name,
            style: AppTypography.bodySmMedium(color: AppColors.textSecondary)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICES GRID — Clay alternating colored cards
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
      'Registered under IBBI for statutory, taxation, transactional, and bank empanelment purposes.',
      'Hello Provaluer, I would like to request Land & Building Valuation details.',
    ],
    [
      'Plant & Machinery Valuation',
      'Technical valuation of industrial assets, factories, assembly lines, and technological equipment.',
      'Hello Provaluer, I would like to request Plant & Machinery Valuation details.',
    ],
    [
      'Securities & Financial Assets',
      'Company valuations, financial instruments, shares, and intangibles for corporate compliance.',
      'Hello Provaluer, I would like to request Securities & Financial Asset Valuation details.',
    ],
    [
      'Net Worth Certificates',
      'Fast-track documentation for Visa applications, bank guarantees, and immigration procedures.',
      'Hello Provaluer, I would like to request a Net Worth Certificate evaluation.',
    ],
    [
      'Chartered Engineer Services',
      'Certification for import-export, customs valuation, machinery life estimation, and government schemes.',
      'Hello Provaluer, I would like to request Chartered Engineer certification services.',
    ],
    [
      'Lenders Independent Engineer',
      'Comprehensive LIE reporting for large infrastructure projects, bank monitoring, and consortium financing.',
      'Hello Provaluer, I would like to request Lenders Independent Engineer (LIE) services.',
    ],
    [
      'Cost Vetting',
      'Financial review of project expenditures, construction budgets, material estimates, and cost overruns.',
      'Hello Provaluer, I would like to request Cost Vetting services.',
    ],
    [
      'Contractors Bill Ratification',
      'Third-party audit and verification of contractor billing, milestones completed, and work quality check.',
      'Hello Provaluer, I would like to request Contractor Bill Ratification services.',
    ],
  ];

  // Clay-palette card variants
  static const _cardVariants = [
    'teal', 'ochre', 'lavender', 'peach',
    'teal', 'pink', 'ochre', 'cream',
  ];

  static const _cardIcons = [
    Icons.apartment_outlined,
    Icons.precision_manufacturing_outlined,
    Icons.trending_up_outlined,
    Icons.description_outlined,
    Icons.engineering_outlined,
    Icons.account_balance_outlined,
    Icons.receipt_long_outlined,
    Icons.fact_check_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);
    return Container(
      color: AppColors.canvas,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.featureOchreLight,
                  borderRadius: AppRadius.brFull,
                  border: Border.all(
                      color: AppColors.featureOchre.withOpacity(0.3)),
                ),
                child: Text('OUR CORE EXPERTISE',
                    style: AppTypography.microUppercase(
                        color: const Color(0xFF7A5A10))),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Professional Engineering\n& Valuation Services',
                style: AppTypography.sectionHeading(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.sectionSm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: isDesktop ? 0.85 : 1.4,
                ),
                itemCount: _services.length,
                itemBuilder: (_, i) => _ServiceCard(
                  title: _services[i][0],
                  description: _services[i][1],
                  message: _services[i][2],
                  variant: _cardVariants[i],
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
  final String variant;
  final IconData icon;
  final Future<void> Function(String) launchWhatsApp;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.message,
    required this.variant,
    required this.icon,
    required this.launchWhatsApp,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  BoxDecoration _deco() {
    switch (widget.variant) {
      case 'teal':
        return BoxDecoration(
          color: AppColors.featureTeal,
          borderRadius: AppRadius.brFeature,
        );
      case 'ochre':
        return BoxDecoration(
          color: AppColors.featureOchreLight,
          borderRadius: AppRadius.brFeature,
          border: Border.all(color: AppColors.featureOchre.withOpacity(0.3)),
        );
      case 'lavender':
        return BoxDecoration(
          color: AppColors.featureLavenderLight,
          borderRadius: AppRadius.brFeature,
          border:
              Border.all(color: AppColors.featureLavender.withOpacity(0.3)),
        );
      case 'peach':
        return BoxDecoration(
          color: AppColors.featurePeachLight,
          borderRadius: AppRadius.brFeature,
          border: Border.all(color: AppColors.featurePeach.withOpacity(0.3)),
        );
      case 'pink':
        return BoxDecoration(
          color: AppColors.featurePinkLight,
          borderRadius: AppRadius.brFeature,
          border: Border.all(color: AppColors.featurePink.withOpacity(0.3)),
        );
      default: // cream
        return BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadius.brFeature,
          border: Border.all(color: AppColors.hairline),
        );
    }
  }

  Color get _iconColor {
    if (widget.variant == 'teal') return AppColors.onDark;
    if (widget.variant == 'ochre') return const Color(0xFF7A5A10);
    if (widget.variant == 'lavender') return const Color(0xFF5A3ABF);
    if (widget.variant == 'peach') return const Color(0xFF8A4010);
    if (widget.variant == 'pink') return AppColors.featurePink;
    return AppColors.deepTeal;
  }

  Color get _iconBg {
    if (widget.variant == 'teal') return AppColors.onDark.withOpacity(0.12);
    return Colors.black.withOpacity(0.05);
  }

  Color get _titleColor =>
      widget.variant == 'teal' ? AppColors.onDark : AppColors.ink;
  Color get _descColor =>
      widget.variant == 'teal' ? AppColors.onDarkMuted : AppColors.textMuted;
  Color get _linkColor =>
      widget.variant == 'teal' ? AppColors.onDark : AppColors.deepTeal;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: _deco().copyWith(
            boxShadow: _hovered ? AppShadows.subtle : AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(widget.icon, color: _iconColor, size: 20),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: AppTypography.cardTitle(color: _titleColor)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(widget.description,
                        style: AppTypography.bodySm(color: _descColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () => widget.launchWhatsApp(widget.message),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Get Enquiry',
                        style: AppTypography.bodySmMedium(color: _linkColor)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 13, color: _linkColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHY CHOOSE US
// ═══════════════════════════════════════════════════════════════════════════════

class WhyChooseUsSection extends StatelessWidget {
  final bool isDesktop;
  const WhyChooseUsSection({super.key, required this.isDesktop});

  static const _reasons = [
    [Icons.verified_outlined, 'IBBI Registered', 'Our valuers are registered under the Insolvency and Bankruptcy Board of India for all asset classes.'],
    [Icons.account_balance_outlined, 'Bank Empanelled', 'Empanelled with 20+ leading banks and NBFCs for mortgage and collateral valuations.'],
    [Icons.speed_outlined, 'Fast Turnaround', '24-48 hour turnaround for standard reports. Expedited service available.'],
    [Icons.gavel_outlined, 'Legally Compliant', 'All reports comply with SEBI, RBI, IBBI, and Customs regulations.'],
    [Icons.support_agent_outlined, 'Expert Team', 'Chartered Engineers and Registered Valuers with 10+ years domain expertise.'],
    [Icons.star_outline_rounded, '100% Accuracy', 'Rigorous QC process ensures every report meets institutional-grade accuracy standards.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceSoft,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: AppColors.deepTeal.withOpacity(0.2)),
                ),
                child: Text('WHY CHOOSE US',
                    style: AppTypography.microUppercase(color: AppColors.deepTeal)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Built for Banks, Trusted\nby Institutions',
                style: AppTypography.sectionHeading(color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sectionSm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: isDesktop ? 1.6 : 3.5,
                ),
                itemCount: _reasons.length,
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: AppComponents.cardBase(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: AppRadius.brMd,
                        ),
                        child: Icon(_reasons[i][0] as IconData,
                            color: AppColors.deepTeal, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_reasons[i][1] as String,
                                style:
                                    AppTypography.cardTitle(color: AppColors.ink)
                                        .copyWith(fontSize: 15)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(_reasons[i][2] as String,
                                style: AppTypography.bodySm(
                                    color: AppColors.textMuted),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
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
// VALUATION WORKFLOW
// ═══════════════════════════════════════════════════════════════════════════════

class ValuationWorkflowSection extends StatelessWidget {
  final bool isDesktop;
  const ValuationWorkflowSection({super.key, required this.isDesktop});

  static const _steps = [
    ['01', 'Submit Request', 'Share property details and documents via our secure client portal or WhatsApp.'],
    ['02', 'Site Inspection', 'Our registered valuer visits the property and conducts a thorough physical inspection.'],
    ['03', 'Analysis & Report', 'Data is analyzed using approved methodologies and compiled into a detailed valuation report.'],
    ['04', 'Delivery & Sign', 'Report is digitally signed by the registered valuer and delivered to you and your bank.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.canvas,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.featureLavenderLight,
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: AppColors.featureLavender.withOpacity(0.3)),
                ),
                child: Text('HOW IT WORKS',
                    style: AppTypography.microUppercase(
                        color: const Color(0xFF5A3ABF))),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Valuation in 4 Simple Steps',
                  style: AppTypography.sectionHeading(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.sectionSm),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    _steps.length,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < _steps.length - 1 ? 16 : 0),
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
                      padding: const EdgeInsets.only(bottom: 16),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.deepTeal,
                borderRadius: AppRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Text(number,
                  style: AppTypography.captionBold(color: AppColors.onDark)
                      .copyWith(fontSize: 12)),
            ),
            if (!isLast) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: AppColors.hairline),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            style: AppTypography.cardTitle(color: AppColors.ink)
                .copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.sm),
        Text(description,
            style: AppTypography.bodySm(color: AppColors.textMuted)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHO WE SERVE
// ═══════════════════════════════════════════════════════════════════════════════

class WhoWeServeSection extends StatelessWidget {
  final bool isDesktop;
  const WhoWeServeSection({super.key, required this.isDesktop});

  static const _groups = [
    [
      'Banks & Financial Institutions',
      'Providing technical asset appraisals, LIE audits, and bad-debt valuation backing empanelments.',
      Icons.account_balance_outlined,
    ],
    [
      'Corporates & Businesses',
      'Assisting in statutory audit valuations, mergers/acquisitions, restructuring, and commercial due diligence.',
      Icons.business_outlined,
    ],
    [
      'Manufacturing & Industries',
      'Valuation of factory premises, machinery life, asset capitalization, and EPCG licensing compliance.',
      Icons.precision_manufacturing_outlined,
    ],
    [
      'NBFCs & Fintechs',
      'Collateral verification, digital lending support, and property risk assessment for modern lenders.',
      Icons.credit_card_outlined,
    ],
    [
      'Government & Public Sector',
      'Government scheme valuations, EPCG compliance reports, and public sector asset assessments.',
      Icons.gavel_outlined,
    ],
    [
      'Individuals & HNIs',
      'Personal property valuations for loans, insurance, estate planning, and net worth certifications.',
      Icons.person_outline,
    ],
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.surfaceSoft,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
          vertical: AppSpacing.sectionLg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.featurePeachLight,
                    borderRadius: AppRadius.brFull,
                    border: Border.all(
                        color: AppColors.featurePeach.withOpacity(0.3)),
                  ),
                  child: Text('CLIENT SECTORS',
                      style: AppTypography.microUppercase(
                          color: const Color(0xFF8A4010))),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Industries We\nRegularly Serve',
                    style: AppTypography.sectionHeading(color: AppColors.ink)),
                const SizedBox(height: AppSpacing.sectionSm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 1.8 : 3.5,
                  ),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: AppComponents.cardBase(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.featurePeachLight,
                            borderRadius: AppRadius.brMd,
                          ),
                          child: Icon(_groups[i][2] as IconData,
                              color: const Color(0xFF8A4010), size: 20),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_groups[i][0] as String,
                                  style: AppTypography.cardTitle(color: AppColors.ink)
                                      .copyWith(fontSize: 15)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(_groups[i][1] as String,
                                  style: AppTypography.bodySm(
                                      color: AppColors.textMuted),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
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

// ═══════════════════════════════════════════════════════════════════════════════
// STATS SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class StatsSection extends StatelessWidget {
  final bool isDesktop;
  const StatsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _AnimatedStat(target: 500, suffix: '+', label: 'Reports\nDelivered'),
      _AnimatedStat(target: 20, suffix: '+', label: 'Bank\nEmpanelments'),
      _AnimatedStat(target: 10, suffix: '+', label: 'Years of\nExperience'),
      _AnimatedStat(target: 100, suffix: '%', label: 'Client\nSatisfaction'),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.deepTeal,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionSm,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _interleaveWithDividers(stats),
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [stats[0], stats[1]],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [stats[2], stats[3]],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _interleaveWithDividers(List<Widget> items) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Container(
          width: 1,
          height: 64,
          color: AppColors.onDark.withOpacity(0.15),
        ));
      }
    }
    return result;
  }
}

class _AnimatedStat extends StatelessWidget {
  final int target;
  final String suffix;
  final String label;

  const _AnimatedStat({
    required this.target,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '0$suffix',
          style: AppTypography.statDisplay(color: AppColors.onDark),
        ).animate(delay: 800.ms).custom(
              duration: 2000.ms,
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                '${(target * value).round()}$suffix',
                style: AppTypography.statDisplay(color: AppColors.onDark),
              ),
            ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySm(color: AppColors.onDarkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TESTIMONIALS
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
    return Container(
      width: double.infinity,
      color: AppColors.canvas,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.featurePinkLight,
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: AppColors.featurePink.withOpacity(0.3)),
                ),
                child: Text('CLIENT STORIES',
                    style: AppTypography.microUppercase(
                        color: AppColors.featurePink)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('What Our Clients Say',
                  style: AppTypography.sectionHeading(color: AppColors.ink),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sectionSm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: isDesktop ? 1.3 : 2.5,
                ),
                itemCount: _testimonials.length,
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: AppComponents.cardBase(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stars
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Icon(Icons.star,
                              color: AppColors.featureOchre, size: 14),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: Text('"${_testimonials[i][0]}"',
                            style: AppTypography.bodyMd(color: AppColors.textSecondary)
                                .copyWith(
                                    fontStyle: FontStyle.italic, height: 1.7)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _testimonials[i][1][0],
                              style: AppTypography.captionBold(
                                  color: AppColors.deepTeal),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_testimonials[i][1],
                                  style: AppTypography.bodySmMedium(
                                      color: AppColors.ink)),
                              Text(
                                  '${_testimonials[i][2]} · ${_testimonials[i][3]}',
                                  style: AppTypography.caption(
                                      color: AppColors.textMuted)),
                            ],
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
// FAQ SECTION
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
      'We are empanelled with 20+ banks including State Bank of India, Union Bank, Punjab National Bank, Axis Bank, Central Bank of India, and many more leading lenders.',
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
    return Container(
      width: double.infinity,
      color: AppColors.surfaceSoft,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: AppColors.deepTeal.withOpacity(0.2)),
                ),
                child: Text('FAQ',
                    style: AppTypography.microUppercase(color: AppColors.deepTeal)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Frequently Asked Questions',
                  style: AppTypography.sectionHeading(color: AppColors.ink),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sectionSm),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.hairline),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: AppRadius.brXl,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style:
                            AppTypography.bodyMdMedium(color: AppColors.ink)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.deepTeal,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(widget.answer,
                      style: AppTypography.bodyMd(color: AppColors.textMuted)),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CTA BANNER
// ═══════════════════════════════════════════════════════════════════════════════

class CtaBanner extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const CtaBanner({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.canvas,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sectionSm),
          decoration: BoxDecoration(
            color: AppColors.deepTeal,
            borderRadius: AppRadius.brXxl,
          ),
          child: Column(
            children: [
              Text('Ready to Get Started?',
                  style: AppTypography.sectionHeading(color: AppColors.onDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Connect with our expert valuation team today.\nFast turnaround. Banking-grade accuracy.',
                style: AppTypography.bodyMd(color: AppColors.onDarkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => launchWhatsApp(
                        'Hello Provaluer, I would like to get started with a consultation.'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.onDark,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Text('Request Consultation',
                          style: AppTypography.buttonMd(
                              color: AppColors.deepTeal)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                            color: AppColors.onDark.withOpacity(0.3)),
                      ),
                      child: Text('Client Login',
                          style: AppTypography.buttonMd(color: AppColors.onDark)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════════

class LandingFooter extends StatelessWidget {
  final bool isDesktop;
  const LandingFooter({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.footerBg,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
          vertical: AppSpacing.sectionSm,
        ),
        width: double.infinity,
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
                      const SizedBox(width: AppSpacing.sectionSm),
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
              const SizedBox(height: AppSpacing.xxl),
            ],
            const SizedBox(height: AppSpacing.xxxl),
            Container(height: 1, color: const Color(0xFF1E1E1E)),
            const SizedBox(height: AppSpacing.xl),
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_copyright(), _tagline()],
              )
            else ...[
              _copyright(),
              const SizedBox(height: AppSpacing.xs),
              _tagline(),
            ],
          ],
        ),
      );

  Widget _companyInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppComponents.logo(fontSize: 18, darkMode: true),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              'Provaluer OPC Private Limited\nAccurate Valuations. Professional Insights.\nTrusted Decisions.',
              style: AppTypography.caption(color: AppColors.onDarkMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _credentialChip('IBBI Registered Valuers'),
          const SizedBox(height: 6),
          _credentialChip('Hyderabad & Secunderabad'),
        ],
      );

  Widget _credentialChip(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppColors.onDarkMuted, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.micro(color: AppColors.onDarkMuted)),
        ],
      );

  Widget _footerCol(String heading, List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading,
              style: AppTypography.captionBold(color: AppColors.onDark)),
          const SizedBox(height: AppSpacing.lg),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item,
                    style: AppTypography.caption(color: AppColors.onDarkMuted)),
              )),
        ],
      );

  Widget _copyright() => Text(
        '© 2026 Provaluer OPC Private Limited. All rights reserved.',
        style: AppTypography.micro(color: const Color(0xFF555555)),
      );

  Widget _tagline() => Text(
        'Advisory Engineers & Registered Valuers',
        style: AppTypography.micro(color: const Color(0xFF555555)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEGACY COMPAT — HeroOverlayContent alias
// ═══════════════════════════════════════════════════════════════════════════════

/// Kept for backward compatibility — redirects to HeroSection
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
