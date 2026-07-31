import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_components.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING HEADER
// ═══════════════════════════════════════════════════════════════════════════════

/// Sticky header that transitions from transparent (over dark hero) to
/// solid white (after scrolling). On mobile, collapses to a hamburger.
class LandingHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isTransparent;
  final Future<void> Function(String) launchWhatsApp;
  final VoidCallback? onMenuTap;

  const LandingHeader({
    super.key,
    required this.isDesktop,
    required this.isTransparent,
    required this.launchWhatsApp,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : AppColors.canvas,
        border: Border(
          bottom: BorderSide(
            color: isTransparent ? Colors.transparent : AppColors.hairlineSoft,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppComponents.logo(fontSize: 18, darkMode: isTransparent),
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
                icon: Icon(
                  Icons.menu,
                  color: isTransparent ? AppColors.onDark : AppColors.ink,
                ),
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
          style: AppTypography.bodySmMedium(
            color: isTransparent ? AppColors.onDarkMuted : AppColors.slate,
          ),
        ),
      );

  Widget _pillButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final Color bg;
    final Color fg;
    Border? border;

    if (isPrimary) {
      bg = isTransparent ? AppColors.onDark : AppColors.primary;
      fg = isTransparent ? AppColors.primary : AppColors.onPrimary;
    } else {
      bg = Colors.transparent;
      fg = isTransparent ? AppColors.onDark : AppColors.ink;
      border = Border.all(
        color: isTransparent
            ? const Color(0x40FFFFFF)
            : AppColors.hairlineStrong,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.buttonPadding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brFull,
            border: border,
          ),
          child: Text(label, style: AppTypography.buttonMd(color: fg)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE MENU DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

/// Full-height drawer for mobile navigation — nav links + Login/Consult CTAs.
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
              // Login button — full width
              SizedBox(
                width: double.infinity,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
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
              ),
              const SizedBox(height: AppSpacing.sm),
              // Consult button — full width
              SizedBox(
                width: double.infinity,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      launchWhatsApp(
                        'Hello Provaluer, I would like to consult with your valuation team.',
                      );
                    },
                    child: Container(
                      padding: AppSpacing.buttonPadding,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.brFull,
                      ),
                      alignment: Alignment.center,
                      child: Text('Consult Now',
                          style:
                              AppTypography.buttonMd(color: AppColors.onPrimary)),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(text, style: AppTypography.bodyMd(color: AppColors.ink)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO OVERLAY CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Text content that sits on top of the dark boomerang hero background.
/// All text is white/light for contrast.
class HeroOverlayContent extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;

  const HeroOverlayContent({
    super.key,
    required this.isDesktop,
    required this.launchWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: _textContent(context, w)),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(flex: 4, child: _consultCard()),
                  ],
                )
              : _textContent(context, w),
        ),
      ),
    );
  }

  Widget _textContent(BuildContext context, double w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow badge — yellow pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.yellowLight,
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            'HYDERABAD & SECUNDERABAD',
            style: AppTypography.microUppercase(color: AppColors.yellowDark),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.1, end: 0, duration: 500.ms),

        const SizedBox(height: AppSpacing.xxl),

        // Headline
        Text(
          isDesktop
              ? 'Independent\nValuation &\nAdvisory Services'
              : 'Independent\nValuation &\nAdvisory',
          style: AppTypography.heroDisplayResponsive(w, color: AppColors.onDark),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.15, end: 0, duration: 600.ms),

        const SizedBox(height: AppSpacing.xl),

        // Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Team of IBBI Registered Valuers providing valuation, certification '
            'and engineering advisory services across Hyderabad and Secunderabad.',
            style: AppTypography.subtitle(color: AppColors.onDarkMuted),
          ),
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms),

        const SizedBox(height: AppSpacing.xxxl),

        // Trust marks
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xs,
          children: [
            _trustMark('IBBI Registered Valuers'),
            _trustMark('Empanelled with Leading Banks'),
            _trustMark('Professional Reports'),
            _trustMark('Fast Turnaround'),
          ],
        ).animate(delay: 600.ms).fadeIn(duration: 600.ms),

        const SizedBox(height: AppSpacing.sectionSm),

        // CTA buttons
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _heroButton(
              label: 'WhatsApp Consultation',
              isPrimary: true,
              onTap: () => launchWhatsApp(
                'Hello Provaluer, I am seeking a valuation consultation '
                'for my property/asset.',
              ),
            ),
            _heroButton(
              label: 'Client Login',
              isPrimary: false,
              onTap: () => context.go('/login'),
            ),
          ],
        )
            .animate(delay: 800.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 600.ms),
      ],
    );
  }

  Widget _trustMark(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.successAccent),
          const SizedBox(width: 6),
          Text(text,
              style: AppTypography.caption(color: AppColors.onDarkMuted)),
        ],
      );

  Widget _heroButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.buttonPadding,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.onDark : Colors.transparent,
            borderRadius: AppRadius.brFull,
            border:
                isPrimary ? null : Border.all(color: const Color(0x4DFFFFFF)),
          ),
          child: Text(
            label,
            style: AppTypography.buttonMd(
              color: isPrimary ? AppColors.primary : AppColors.onDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _consultCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF), // ~10% white — glass effect
        borderRadius: AppRadius.brXxl,
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Consultation',
              style: AppTypography.heading4(color: AppColors.onDark)),
          const SizedBox(height: AppSpacing.xs),
          Text('Direct connection to engineering & valuation experts.',
              style: AppTypography.bodySm(color: AppColors.onDarkMuted)),
          const SizedBox(height: AppSpacing.xxl),
          _consultItem('Land & Building Valuation',
              'I would like to inquire about Land & Building Valuation services.'),
          const SizedBox(height: AppSpacing.xs),
          _consultItem('Plant & Machinery Valuation',
              'I would like to inquire about Plant & Machinery Valuation services.'),
          const SizedBox(height: AppSpacing.xs),
          _consultItem('Chartered Engineer Certificate',
              'I would like to inquire about Chartered Engineer services.'),
        ],
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 700.ms)
        .slideX(begin: 0.1, end: 0, duration: 700.ms);
  }

  Widget _consultItem(String label, String message) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchWhatsApp(message),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: AppRadius.brLg,
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style:
                        AppTypography.bodySmMedium(color: AppColors.onDark)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward,
                  size: 14, color: AppColors.onDarkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRUST BAR
// ═══════════════════════════════════════════════════════════════════════════════

/// "Trusted by leading banking institutions" — bank name pill chips.
class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.hairlineSoft),
        ),
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
            style: AppTypography.bodySmMedium(color: AppColors.slate)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICES GRID
// ═══════════════════════════════════════════════════════════════════════════════

/// 8-card services grid with pastel card cycling (yellow/coral/teal/rose).
/// 4-col desktop, 2-col tablet, 1-col mobile.
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

  // Pastel card color cycle — matches sticky-note palette from Design.md
  static const _cardVariants = [
    null, 'yellow', null, 'coral', null, 'teal', null, 'rose',
  ];

  // Icons for each service
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
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
        vertical: AppSpacing.sectionLg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section eyebrow
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellowLight,
                  borderRadius: AppRadius.brFull,
                ),
                child: Text('OUR CORE EXPERTISE',
                    style: AppTypography.microUppercase(
                        color: AppColors.yellowDark)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Professional Engineering\n& Valuation Services',
                style: AppTypography.heading2(color: AppColors.ink),
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

class _ServiceCard extends StatelessWidget {
  final String title, description, message;
  final String? variant;
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

  BoxDecoration _deco() {
    switch (variant) {
      case 'yellow':
        return AppComponents.cardFeatureYellow();
      case 'coral':
        return AppComponents.cardFeatureCoral();
      case 'teal':
        return AppComponents.cardFeatureTeal();
      case 'rose':
        return AppComponents.cardFeatureRose();
      default:
        return AppComponents.cardFeature();
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: _deco(),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon in a small container
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: AppColors.brandBlue, size: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.heading5(color: AppColors.ink)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(description,
                      style: AppTypography.bodySm(color: AppColors.slate),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchWhatsApp(message),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Get Enquiry',
                        style: AppTypography.bodySmMedium(
                            color: AppColors.brandBlue)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        size: 13, color: AppColors.brandBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// WHO WE SERVE
// ═══════════════════════════════════════════════════════════════════════════════

/// 3-card industry sector grid with icons.
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
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.surface,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
          vertical: AppSpacing.sectionLg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section eyebrow
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text('CLIENT SECTORS',
                      style: AppTypography.microUppercase(
                          color: AppColors.coralDark)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Industries We\nRegularly Serve',
                    style: AppTypography.heading2(color: AppColors.ink)),
                const SizedBox(height: AppSpacing.sectionSm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 1.5 : 2.5,
                  ),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: AppComponents.cardFeature(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: AppRadius.brMd,
                          ),
                          child: Icon(_groups[i][2] as IconData,
                              color: AppColors.brandBlue, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_groups[i][0] as String,
                                  style: AppTypography.heading5(
                                      color: AppColors.ink)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(_groups[i][1] as String,
                                  style: AppTypography.bodySm(
                                      color: AppColors.slate)),
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

/// Animated stat counters — numbers count up using flutter_animate.
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
      color: AppColors.surfaceSoft,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
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
          color: AppColors.hairline,
        ));
      }
    }
    return result;
  }
}

/// Individual animated stat counter using flutter_animate's custom effect.
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
          style: AppTypography.statDisplay(color: AppColors.brandBlue),
        ).animate(delay: 800.ms).custom(
              duration: 2000.ms,
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                '${(target * value).round()}$suffix',
                style:
                    AppTypography.statDisplay(color: AppColors.brandBlue),
              ),
            ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySm(color: AppColors.slate),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CTA BANNER
// ═══════════════════════════════════════════════════════════════════════════════

/// Dark CTA band — "Ready to get started?" with white-on-dark pill button.
class CtaBanner extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const CtaBanner({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.canvas,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.section),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.brFeature,
          ),
          child: Column(
            children: [
              Text('Ready to get started?',
                  style: AppTypography.heading2(color: AppColors.onDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Connect with our expert valuation team today.',
                style: AppTypography.subtitle(color: AppColors.onDarkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => launchWhatsApp(
                    'Hello Provaluer, I would like to get started with a consultation.'),
                style: AppComponents.onDarkButtonStyle(),
                child: Text('Get Started Free',
                    style:
                        AppTypography.buttonMd(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════════

/// Dark footer with company info, IBBI credentials, and copyright.
class LandingFooter extends StatelessWidget {
  final bool isDesktop;
  const LandingFooter({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.footerBg,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
          vertical: AppSpacing.section,
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
                  _credentials(),
                ],
              )
            else ...[
              _companyInfo(),
              const SizedBox(height: AppSpacing.xxl),
              _credentials(),
            ],
            const SizedBox(height: AppSpacing.xxxl),
            Container(height: 1, color: const Color(0xFF2C2C2C)),
            const SizedBox(height: AppSpacing.xl),
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _copyright(),
                  _tagline(),
                ],
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
          const SizedBox(height: AppSpacing.sm),
          Text('Provaluer OPC Private Limited',
              style: AppTypography.bodySmMedium(color: AppColors.onDark)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
              'Accurate Valuations. Professional Insights. Trusted Decisions.',
              style: AppTypography.micro(color: AppColors.onDarkMuted)),
        ],
      );

  Widget _credentials() => Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text('IBBI Registered Valuers',
              style: AppTypography.micro(color: AppColors.onDarkMuted)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.onDarkMuted, size: 13),
              const SizedBox(width: AppSpacing.xxs),
              Text('Hyderabad & Secunderabad',
                  style: AppTypography.micro(color: AppColors.onDarkMuted)),
            ],
          ),
        ],
      );

  Widget _copyright() => Text(
        '© 2026 Provaluer OPC Private Limited. All rights reserved.',
        style: AppTypography.micro(color: const Color(0xFF666666)),
      );

  Widget _tagline() => Text(
        'Advisory Engineers & Registered Valuers',
        style: AppTypography.micro(color: const Color(0xFF666666)),
      );
}
