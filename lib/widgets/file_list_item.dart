import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/pdf_processing_service.dart';
import '../spdfcore.dart';

class FileListItem extends StatelessWidget {
  final File file;
  final int index;
  final bool canReorder;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const FileListItem({
    super.key,
    required this.file,
    required this.index,
    required this.canReorder,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    final fileSize = _getFileSize();
    final fileExtension = fileName.split('.').last.toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getFileIcon(),
                  color: _getFileColor(),
                  size: 20,
                ),
                Text(
                  fileExtension,
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: _getFileColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Show PDF information using spdfcore
                FutureBuilder<PdfInfo?>(
                  future: fileName.toLowerCase().endsWith('.pdf') 
                      ? PDFProcessingService.getPdfInfo(file.path)
                      : null,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final pdfInfo = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pdfInfo.pageCount} pages • ${PDFProcessingService.formatFileSize(pdfInfo.fileSize)}',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                          if (!pdfInfo.isValid)
                            Text(
                              'Invalid PDF',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      );
                    } else if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Analyzing PDF...',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.black38,
                        ),
                      );
                    } else {
                      return Text(
                        fileSize,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Reorder buttons (if applicable)
          if (canReorder) ...[
            Column(
              children: [
                InkWell(
                  onTap: onMoveUp,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: onMoveUp != null 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 16,
                      color: onMoveUp != null 
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onMoveDown,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: onMoveDown != null 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: onMoveDown != null 
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          
          // Remove button
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'bmp':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _getFileColor() {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red.shade600;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'bmp':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getFileSize() {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }
}