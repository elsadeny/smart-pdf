import 'package:flutter/material.dart';

enum ToolType {
  merge,
  split,
  compress,
  lockUnlock,
  imageToPdf,
  moreTools,
}

class PDFTool {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final ToolType type;
  final bool requiresRewardedAd;
  final bool isComingSoon;

  const PDFTool({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.type,
    this.requiresRewardedAd = false,
    this.isComingSoon = false,
  });

  static List<PDFTool> get allTools => [
        const PDFTool(
          id: 'merge',
          title: 'Merge PDF',
          description: 'Combine multiple PDFs into one',
          icon: Icons.merge_type_rounded,
          iconColor: Color(0xFF4CAF50),
          type: ToolType.merge,
        ),
        const PDFTool(
          id: 'split',
          title: 'Split PDF',
          description: 'Extract pages from PDF',
          icon: Icons.content_cut_rounded,
          iconColor: Color(0xFFFF9800),
          type: ToolType.split,
        ),
        const PDFTool(
          id: 'compress',
          title: 'Compress PDF',
          description: 'Reduce PDF file size',
          icon: Icons.compress_rounded,
          iconColor: Color(0xFF2196F3),
          type: ToolType.compress,
        ),
        const PDFTool(
          id: 'lock_unlock',
          title: 'Lock/Unlock PDF',
          description: 'Add or remove password protection',
          icon: Icons.lock_outline_rounded,
          iconColor: Color(0xFFF44336),
          type: ToolType.lockUnlock,
          requiresRewardedAd: true,
        ),
        const PDFTool(
          id: 'image_to_pdf',
          title: 'Image to PDF',
          description: 'Convert images to PDF format',
          icon: Icons.image_outlined,
          iconColor: Color(0xFF9C27B0),
          type: ToolType.imageToPdf,
          requiresRewardedAd: true,
        ),
        const PDFTool(
          id: 'more_tools',
          title: 'More Tools',
          description: 'Coming soon...',
          icon: Icons.more_horiz_rounded,
          iconColor: Color(0xFF607D8B),
          type: ToolType.moreTools,
          isComingSoon: true,
        ),
      ];
}