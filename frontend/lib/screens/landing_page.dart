import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_components.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const String _waUrl = "https://wa.me/918500880333";

  Future<void> _launchWhatsApp(String message) async {
    final url = Uri.parse("$_waUrl?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;
    final isTablet  = w >= 768 && w < 1024;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _Header(isDesktop: isDesktop, launchWhatsApp: _launchWhatsApp),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroSection(isDesktop: isDesktop, launchWhatsApp: _launchWhatsApp),
                  _TrustBar(),
                  _ServicesSection(isDesktop: isDesktop, isTablet: isTablet, launchWhatsApp: _launchWhatsApp),
                  _WhoWeServeSection(isDesktop: isDesktop),
                  _CtaBanner(launchWhatsApp: _launchWhatsApp),
                  _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;
  const _Header({required this.isDesktop, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.xxl : AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.hairlineSoft, width: 1)),
      ),
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
              // button-secondary pill
              _pillButton(
                label: 'Client Login',
                isPrimary: false,
                onTap: () => context.go('/login'),
              ),
              const SizedBox(width: AppSpacing.sm),
              // button-primary pill
              _pillButton(
                label: 'Consult Now',
                isPrimary: true,
                onTap: () => launchWhatsApp(
                  'Hello Provaluer, I would like to consult with your valuation team.',
                ),
              ),
            ]),
          ] else
            _pillButton(
              label: 'Login',
              isPrimary: true,
              onTap: () => context.go('/login'),
            ),
        ],
      ),
    );
  }

  Widget _navLink(String text) => Text(
        text,
        style: AppTypography.bodySmMedium(color: AppColors.slate),
      );

  Widget _pillButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.buttonPadding,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.canvas,
          borderRadius: AppRadius.brFull,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.hairlineStrong),
        ),
        child: Text(
          label,
          style: AppTypography.buttonMd(
            color: isPrimary ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;
  const _HeroSection({required this.isDesktop, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      color: AppColors.canvas,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.md,
        vertical: isDesktop ? AppSpacing.sectionLg : AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _heroContent(w)),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(flex: 4, child: _consultCard()),
                  ],
                )
              : _heroContent(w),
        ),
      ),
    );
  }

  Widget _heroContent(double w) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow tag — yellow pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceYellow,
              borderRadius: AppRadius.brFull,
            ),
            child: Text(
              'HYDERABAD & SECUNDERABAD',
              style: AppTypography.microUppercase(color: AppColors.yellowDark),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Hero headline — responsive scale
          Text(
            isDesktop
                ? 'Independent\nValuation &\nAdvisory Services'
                : 'Independent\nValuation &\nAdvisory',
            style: AppTypography.heroDisplayResponsive(w, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Team of IBBI Registered Valuers providing valuation, certification and engineering advisory services across Hyderabad and Secunderabad.',
              style: AppTypography.subtitle(color: AppColors.slate),
            ),
          ),
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
          ),
          const SizedBox(height: AppSpacing.sectionSm),
          // CTA row — pill buttons
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ctaButton(
                label: 'WhatsApp Consultation',
                isPrimary: true,
                onTap: () => launchWhatsApp(
                  'Hello Provaluer, I am seeking a valuation consultation for my property/asset.',
                ),
              ),
              _ctaButton(
                label: 'Client Login',
                isPrimary: false,
                onTap: () {},
              ),
            ],
          ),
        ],
      );

  Widget _trustMark(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: AppColors.successAccent),
          const SizedBox(width: 6),
          Text(text, style: AppTypography.caption(color: AppColors.slate)),
        ],
      );

  Widget _ctaButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.buttonPadding,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.canvas,
            borderRadius: AppRadius.brFull,
            border: isPrimary ? null : Border.all(color: AppColors.hairlineStrong),
          ),
          child: Text(
            label,
            style: AppTypography.buttonMd(
              color: isPrimary ? AppColors.onPrimary : AppColors.ink,
            ),
          ),
        ),
      );

  // Consult card (desktop right panel)
  Widget _consultCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brXxxl,
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Consultation',
                style: AppTypography.heading4(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.xs),
            Text('Direct connection to engineering & valuation experts.',
                style: AppTypography.bodySm(color: AppColors.slate)),
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
      );

  Widget _consultItem(String label, String message) => GestureDetector(
        onTap: () => launchWhatsApp(message),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTypography.bodySmMedium(color: AppColors.ink)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward, size: 14, color: AppColors.brandBlue),
            ],
          ),
        ),
      );
}

// ── Trust Bar ─────────────────────────────────────────────────────────────────
class _TrustBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xxl),
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
              children: [
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

  Widget _bankChip(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.brFull,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(name, style: AppTypography.bodySmMedium(color: AppColors.slate)),
      );
}

// ── Services Section ──────────────────────────────────────────────────────────
class _ServicesSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final Future<void> Function(String) launchWhatsApp;
  const _ServicesSection(
      {required this.isDesktop, required this.isTablet, required this.launchWhatsApp});

  static const _services = [
    ['Land & Building Valuation',
     'Registered under IBBI for statutory, taxation, transactional, and bank empanelment purposes.',
     'Hello Provaluer, I would like to request Land & Building Valuation details.'],
    ['Plant & Machinery Valuation',
     'Technical valuation of industrial assets, factories, assembly lines, and technological equipment.',
     'Hello Provaluer, I would like to request Plant & Machinery Valuation details.'],
    ['Securities & Financial Assets',
     'Company valuations, financial instruments, shares, and intangibles for corporate compliance.',
     'Hello Provaluer, I would like to request Securities & Financial Asset Valuation details.'],
    ['Net Worth Certificates',
     'Fast-track documentation for Visa applications, bank guarantees, and immigration procedures.',
     'Hello Provaluer, I would like to request a Net Worth Certificate evaluation.'],
    ['Chartered Engineer Services',
     'Certification for import-export, customs valuation, machinery life estimation, and government schemes.',
     'Hello Provaluer, I would like to request Chartered Engineer certification services.'],
    ['Lenders Independent Engineer',
     'Comprehensive LIE reporting for large infrastructure projects, bank monitoring, and consortium financing.',
     'Hello Provaluer, I would like to request Lenders Independent Engineer (LIE) services.'],
    ['Cost Vetting',
     'Financial review of project expenditures, construction budgets, material estimates, and cost overruns.',
     'Hello Provaluer, I would like to request Cost Vetting services.'],
    ['Contractors Bill Ratification',
     'Third-party audit and verification of contractor billing, milestones completed, and work quality check.',
     'Hello Provaluer, I would like to request Contractor Bill Ratification services.'],
  ];

  // Pastel card colors cycle — matches sticky-note palette from Design.md
  static const _cardDecorations = [
    null,            // white
    'yellow',
    null,
    'coral',
    null,
    'teal',
    null,
    'rose',
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
              AppComponents.badgeTagYellow('OUR CORE EXPERTISE'),
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
                  childAspectRatio: isDesktop ? 0.85 : 1.1,
                ),
                itemCount: _services.length,
                itemBuilder: (_, i) => _ServiceCard(
                  title: _services[i][0],
                  description: _services[i][1],
                  message: _services[i][2],
                  variant: _cardDecorations[i],
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
  final Future<void> Function(String) launchWhatsApp;
  const _ServiceCard({
    required this.title,
    required this.description,
    required this.message,
    required this.variant,
    required this.launchWhatsApp,
  });

  BoxDecoration _deco() {
    switch (variant) {
      case 'yellow': return AppComponents.cardFeatureYellow();
      case 'coral':  return AppComponents.cardFeatureCoral();
      case 'teal':   return AppComponents.cardFeatureTeal();
      case 'rose':   return AppComponents.cardFeatureRose();
      default:       return AppComponents.cardFeature();
    }
  }

  Color get _textColor =>
      variant != null ? AppColors.ink : AppColors.ink;

  @override
  Widget build(BuildContext context) => Container(
        decoration: _deco(),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.heading5(color: _textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(description,
                      style: AppTypography.bodySm(color: AppColors.slate)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => launchWhatsApp(message),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Get Enquiry',
                      style: AppTypography.bodySmMedium(color: AppColors.brandBlue)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 13, color: AppColors.brandBlue),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Who We Serve ──────────────────────────────────────────────────────────────
class _WhoWeServeSection extends StatelessWidget {
  final bool isDesktop;
  const _WhoWeServeSection({required this.isDesktop});

  static const _groups = [
    ['Banks & Financial Institutions',
     'Providing technical asset appraisals, LIE audits, and bad-debt valuation backing empanelments.',
     Icons.account_balance_outlined],
    ['Corporates & Businesses',
     'Assisting in statutory audit valuations, mergers/acquisitions, restructuring, and commercial due diligence.',
     Icons.business_outlined],
    ['Manufacturing & Industries',
     'Valuation of factory premises, machinery life, asset capitalization, and EPCG licensing compliance.',
     Icons.precision_manufacturing_outlined],
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
                AppComponents.badgeTagCoral('CLIENT SECTORS'),
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
                            color: AppColors.surface,
                            borderRadius: AppRadius.brMd,
                          ),
                          child: Icon(_groups[i][2] as IconData,
                              color: AppColors.slate, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_groups[i][0] as String,
                                  style: AppTypography.heading5(color: AppColors.ink)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(_groups[i][1] as String,
                                  style: AppTypography.bodySm(color: AppColors.slate)),
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

// ── CTA Banner (dark) ─────────────────────────────────────────────────────────
class _CtaBanner extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;
  const _CtaBanner({required this.launchWhatsApp});

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
                    style: AppTypography.buttonMd(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.footerBg,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionLg, vertical: AppSpacing.section),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppComponents.logo(fontSize: 18, darkMode: true),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Provaluer OPC Private Limited',
                        style: AppTypography.bodySmMedium(color: AppColors.onDark)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('Accurate Valuations. Professional Insights. Trusted Decisions.',
                        style: AppTypography.micro(color: AppColors.onDarkMuted)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Container(height: 1, color: const Color(0xFF2C2C2C)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 Provaluer OPC Private Limited. All rights reserved.',
                  style: AppTypography.micro(color: const Color(0xFF666666)),
                ),
                Text(
                  'Advisory Engineers & Registered Valuers',
                  style: AppTypography.micro(color: const Color(0xFF666666)),
                ),
              ],
            ),
          ],
        ),
      );
}
