import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../spdfcore_rust.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _coreVersion = 'Loading...';
  final SpdfcoreRust _spdfcoreRust = SpdfcoreRust();
  
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }
  
  Future<void> _loadVersion() async {
    try {
      final version = await _spdfcoreRust.getVersion();
      if (mounted) {
        setState(() {
          _coreVersion = version;
        });
      }
    } catch (e) {
      print('Error loading spdfcore version: $e');
      if (mounted) {
        setState(() {
          _coreVersion = 'Error loading version';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/pdg-logo.jpg',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('About'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App info card
                  _buildAppInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Features section
                  _buildFeaturesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Links section
                  _buildLinksSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Support section
                  _buildSupportSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Version info
                  _buildVersionInfo(),
                ],
              ),
            ),
          ),
          
          // Banner ad
          _buildBannerAd(),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App name
            Text(
              'SmartPDF',
              style: AppTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App description
            Text(
              'All-in-one PDF tools for merging, compressing, converting, and protecting your documents.',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.merge_type_rounded,
        'title': 'Merge PDFs',
        'description': 'Combine multiple PDF files into one document',
        'color': Color(0xFF4CAF50),
      },
      {
        'icon': Icons.content_cut_rounded,
        'title': 'Split PDFs',
        'description': 'Extract specific pages from PDF documents',
        'color': Color(0xFFFF9800),
      },
      {
        'icon': Icons.compress_rounded,
        'title': 'Compress PDFs',
        'description': 'Reduce file size without losing quality',
        'color': Color(0xFF2196F3),
      },
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'Protect PDFs',
        'description': 'Add or remove password protection',
        'color': Color(0xFFF44336),
      },
      {
        'icon': Icons.image_outlined,
        'title': 'Image to PDF',
        'description': 'Convert images to PDF format',
        'color': Color(0xFF9C27B0),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(feature)),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: feature['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'],
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal & Privacy',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildLinkItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _launchUrl('https://example.com/privacy'),
        ),
        _buildLinkItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () => _launchUrl('https://example.com/terms'),
        ),
        _buildLinkItem(
          icon: Icons.security_outlined,
          title: 'Data Security',
          onTap: () => _showDataSecurityDialog(context),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildLinkItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & FAQ',
          onTap: () => _showHelpDialog(context),
        ),
        _buildLinkItem(
          icon: Icons.email_outlined,
          title: 'Contact Support',
          onTap: () => _launchUrl('mailto:support@smartpdf.app'),
        ),
        _buildLinkItem(
          icon: Icons.star_outline_rounded,
          title: 'Rate the App',
          onTap: () => _showRatingDialog(context),
        ),
      ],
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: AppTheme.textTheme.titleMedium,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Core Version',
                  style: AppTheme.textTheme.titleMedium,
                ),
                Text(
                  _coreVersion,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Build',
                  style: AppTheme.textTheme.titleMedium,
                ),
                Text(
                  '1',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Made with',
                  style: AppTheme.textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Flutter',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAd() {
    return Consumer<AdService>(
      builder: (context, adService, child) {
        if (!adService.isBannerAdLoaded || adService.bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AdWidget(ad: adService.bannerAd!),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDataSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Security'),
        content: const Text(
          'SmartPDF processes all files locally on your device. No files are uploaded to external servers, ensuring your documents remain private and secure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const Text(
          'For help and frequently asked questions, please visit our support website or contact us directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('https://example.com/help');
            },
            child: const Text('Visit Help'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate SmartPDF'),
        content: const Text(
          'If you enjoy using SmartPDF, please consider rating us on the app store. Your feedback helps us improve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app store rating page
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}