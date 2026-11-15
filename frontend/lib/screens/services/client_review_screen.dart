import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/landing/landing_theme.dart';
import '../../services/analytics_service.dart';

/// Client Feedback & Review Screen
/// Canonical URL: https://www.provaluer.in/review
class ClientReviewScreen extends StatelessWidget {
  const ClientReviewScreen({super.key});

  static const String _googleReviewUrl = 'https://www.google.com/search?q=ProValuer+Commercial+Hyderabad';
  static const String _primaryPhone = '+918500880333';
  static const Color _obsidian = Color(0xFF0F172A);
  static const Color _slateText = Color(0xFF475569);
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _borderSubtle = Color(0xFFE2E8F0);

  Future<void> _launchCall() async {
    AnalyticsService.logLeadCallClick(
      serviceType: 'CLIENT_REVIEW',
      phoneNumber: _primaryPhone,
    );
    final uri = Uri.parse('tel:$_primaryPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchGoogleReview() async {
    AnalyticsService.logEvent(
      'google_review_click',
      serviceType: 'CLIENT_REVIEW',
      additionalParams: {'target_url': _googleReviewUrl},
    );
    final uri = Uri.parse(_googleReviewUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchWhatsApp() async {
    AnalyticsService.logLeadWhatsAppClick(
      serviceType: 'CLIENT_REVIEW',
      target: 'https://wa.me/918500880333',
    );
    final uri = Uri.parse('https://wa.me/918500880333?text=Hi%20ProValuer%20Team%2C%20following%20up%20on%20my%20valuation%20report');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1024;

    final feedbackItems = [
      {
        'title': 'Capital Gains Section 50C Assessment Defense',
        'desc': 'Assessed commercial parcel in Jubilee Hills with topographical encumbrances. The rigorous valuation report was admitted before the Income Tax Assessing Officer under Section 50C(2) without DVO referral.',
        'tag': 'Wealth Tax Act Sec 34AB',
        'rating': '★★★★★',
      },
      {
        'title': 'US F-1 Visa Solvency Valuation Dossier',
        'desc': 'Expedited multi-asset valuation for independent residential villa & commercial units delivered within 48 hours. Fully accepted at the US Consulate financial solvency interview.',
        'tag': 'Embassy Accepted',
        'rating': '★★★★★',
      },
      {
        'title': 'Patancheru Industrial Manufacturing Plant Appraisal',
        'desc': 'Comprehensive Depreciated Replacement Cost (DRC) and residual life audit of 420 plant machinery assets. Accepted by lead consortium bank for working capital credit facility.',
        'tag': 'Bank Collateral & P&M',
        'rating': '★★★★★',
      },
      {
        'title': 'High Court Probate & Inheritance Partition',
        'desc': 'Independent court-admissible valuation report for Banjara Hills ancestral estate partition. Established transparent Fair Market Value facilitating family settlement agreement.',
        'tag': 'Court Admissible',
        'rating': '★★★★★',
      },
    ];

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: AppBar(
        backgroundColor: _pureWhite,
        elevation: 0,
        title: Text('Client Feedback & Reviews', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: _obsidian)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _obsidian),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20, vertical: 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderSubtle),
                      boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 15, offset: Offset(0, 6))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('VERIFIED CLIENT EXPERIENCE', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 16),
                        const Text('★★★★★', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 28, letterSpacing: 4)),
                        const SizedBox(height: 12),
                        Text(
                          'Thank You for Choosing Pro Valuer',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: _obsidian),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We are committed to delivering the highest caliber of statutory, banking, and commercial asset appraisals across India. Please take 30 seconds to review your experience on Google.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _launchGoogleReview,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 16, color: Colors.white),
                          label: const Text('Review Us on Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Verified Mandate Feedback & Case Highlights', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: _obsidian)),
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: feedbackItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final item = feedbackItems[i];
                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _pureWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: LandingTheme.accentSubtle, borderRadius: BorderRadius.circular(6)),
                                  child: Text(item['tag']!, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: LandingTheme.primaryAccent)),
                                ),
                                Text(item['rating']!, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14, letterSpacing: 2)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item['title']!, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _obsidian)),
                            const SizedBox(height: 8),
                            Text(item['desc']!, style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.5)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Back to Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _obsidian,
                          side: const BorderSide(color: _borderSubtle),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _launchCall,
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                        label: const Text('Call Desk'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _obsidian,
                          side: const BorderSide(color: _borderSubtle),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _launchWhatsApp,
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
