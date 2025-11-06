import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pdf_tool.dart';
import '../widgets/tool_card.dart';
import '../services/ad_service.dart';
import '../services/pdf_file_service.dart';
import '../theme/app_theme.dart';
import 'files_screen.dart';
import 'about_screen.dart';
import 'tool_screen.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<PDFTool> _allTools = PDFTool.allTools;
  List<PDFTool> _filteredTools = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredTools = _allTools;
    _initializeAds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeAds() async {
    final adService = Provider.of<AdService>(context, listen: false);
    await adService.initializeAds();
  }

  void _filterTools(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTools = _allTools;
      } else {
        _filteredTools = _allTools
            .where((tool) =>
                tool.title.toLowerCase().contains(query.toLowerCase()) ||
                tool.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onToolTap(PDFTool tool) {
    final adService = Provider.of<AdService>(context, listen: false);

    if (tool.requiresRewardedAd) {
      _showRewardedAdDialog(tool, adService);
    } else {
      _navigateToTool(tool);
    }
  }

  void _showRewardedAdDialog(PDFTool tool, AdService adService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Watch Ad to Continue'),
          ],
        ),
        content: Text(
          'Watch a short ad to unlock the ${tool.title} tool.',
          style: AppTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              adService.showRewardedAd(
                onUserEarnedReward: () => _navigateToTool(tool),
                onAdClosed: () {
                  // Show message if ad was closed without reward
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please watch the complete ad to unlock ${tool.title}',
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  void _navigateToTool(PDFTool tool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ToolScreen(tool: tool),
      ),
    );
  }

   Future<void> _openPDFFile() async {
    try {
      final filePath = await PDFFileService.pickPDFFile();
      if (filePath != null) {
        final fileName = PDFFileService.getFileName(filePath);
        
        // Add to recent files
        await PDFFileService.addToRecentFiles(filePath);
        
        // Navigate to PDF viewer
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                filePath: filePath,
                fileName: fileName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('SmartPDF'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final adService = Provider.of<AdService>(context, listen: false);
              adService.refreshNativeAd();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing ads...')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to recent files
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FilesScreen(),
            ),
          );
        },
        child: const Icon(Icons.history_rounded),
        tooltip: 'Recent Files',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FilesScreen(),
                ),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'About',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search bar
        _buildSearchBar(),
        
        // Open PDF button
        _buildOpenPDFButton(),
        
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tools grid
                _buildToolsGrid(),
                
                const SizedBox(height: 24),
                
                // Native ad
                _buildNativeAd(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterTools,
        decoration: InputDecoration(
          hintText: 'Search tools...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.black54,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterTools('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredTools.length,
      itemBuilder: (context, index) {
        final tool = _filteredTools[index];
        return ToolCard(
          tool: tool,
          onTap: () => _onToolTap(tool),
        );
      },
    );
  }

  Widget _buildNativeAd() {
    return Consumer<AdService>(
      builder: (context, adService, child) {
        if (!adService.isNativeAdLoaded || adService.nativeAd == null) {
          return Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black12,
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading ad...',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AdWidget(ad: adService.nativeAd!),
          ),
        );
      },
    );
  }

  Widget _buildOpenPDFButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _openPDFFile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/pdg-logo.jpg',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('Open PDF File'),
          ],
        ),
      ),
    );
  }
}