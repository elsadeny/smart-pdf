import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/pdf_tool.dart';
import '../services/ad_service.dart';
import '../services/pdf_processing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/file_list_item.dart';
import '../widgets/progress_overlay.dart';
import 'pdf_viewer_screen.dart';

class ToolScreen extends StatefulWidget {
  final PDFTool tool;

  const ToolScreen({super.key, required this.tool});

  @override
  State<ToolScreen> createState() => _ToolScreenState();
}

class _ToolScreenState extends State<ToolScreen> {
  List<File> _selectedFiles = [];
  bool _isProcessing = false;
  String _processingMessage = '';
  String? _resultMessage;
  Map<String, String>? _resultStats;
  String? _resultFilePath;
  List<String>? _splitResultFiles;  // For storing multiple split output files
  int _splitPage = 1;  // For split PDF functionality
  final _splitPageController = TextEditingController();

  @override
  void dispose() {
    _splitPageController.dispose();
    super.dispose();
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
            Text(widget.tool.title),
          ],
        ),
        backgroundColor: widget.tool.iconColor.withOpacity(0.1),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool description
                      _buildToolDescription(),
                      
                      const SizedBox(height: 24),
                      
                      // Step 1: File selection
                      _buildFileSelectionSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Step 2: Selected files (if any)
                      if (_selectedFiles.isNotEmpty) ...[
                        _buildSelectedFilesSection(),
                        const SizedBox(height: 24),
                      ],
                      
                      // Step 2.5: Split page input (for split PDF only)
                      if (_selectedFiles.isNotEmpty && widget.tool.type == ToolType.split) ...[
                        _buildSplitPageInputSection(),
                        const SizedBox(height: 24),
                      ],
                      
                      // Step 3: Action button
                      _buildActionSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Result section
                      if (_resultMessage != null) ...[
                        _buildResultSection(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Banner ad
              _buildBannerAd(),
            ],
          ),
          
          // Processing overlay
          if (_isProcessing) ProgressOverlay(message: _processingMessage),
        ],
      ),
    );
  }

  Widget _buildToolDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.tool.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.tool.icon,
                color: widget.tool.iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tool.title,
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tool.description,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStepTitle(),
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // File selection button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: Icon(
              _getSelectionIcon(),
              color: widget.tool.iconColor,
            ),
            label: Text(_getSelectionButtonText()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              side: BorderSide(color: widget.tool.iconColor, width: 2),
              foregroundColor: widget.tool.iconColor,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // File format info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFileFormatInfo(),
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Selected Files (${_selectedFiles.length})',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _selectedFiles.clear()),
              icon: const Icon(Icons.clear_all_rounded, size: 20),
              label: const Text('Clear All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Files list
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _selectedFiles.length; i++) ...[
                FileListItem(
                  file: _selectedFiles[i],
                  index: i,
                  canReorder: widget.tool.type == ToolType.merge,
                  onRemove: () => _removeFile(i),
                  onMoveUp: i > 0 ? () => _moveFile(i, i - 1) : null,
                  onMoveDown: i < _selectedFiles.length - 1 ? () => _moveFile(i, i + 1) : null,
                ),
                if (i < _selectedFiles.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitPageInputSection() {
    return FutureBuilder<int?>(
      future: _getSelectedFilePagesCount(),
      builder: (context, snapshot) {
        final totalPages = snapshot.data ?? 1;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Split Point',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Split page input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split after page:',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _splitPageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter page number (1-${totalPages - 1})',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            errorText: _getSplitPageError(totalPages),
                          ),
                          onChanged: (value) {
                            final page = int.tryParse(value);
                            setState(() {
                              if (page != null && page > 0 && page < totalPages) {
                                _splitPage = page;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'of $totalPages',
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Split preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Split preview:',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  'Part 1: Pages 1-$_splitPage',
                                  style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  'Part 2: Pages ${_splitPage + 1}-$totalPages',
                                  style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _selectedFiles.isNotEmpty ? AppTheme.primaryColor : Colors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.tool.type == ToolType.split && _selectedFiles.isNotEmpty ? '4' : '3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Process Files',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: _selectedFiles.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canProcessFiles() ? _processFiles : null,
            icon: Icon(_getActionIcon()),
            label: Text(_getActionButtonText()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: widget.tool.iconColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Process Completed!',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _resultMessage!,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.green.shade700,
              ),
            ),
            
            if (_resultStats != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    for (final entry in _resultStats!.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              entry.value,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openResultFile,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareResultFile,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.tool.iconColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
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

  // Helper methods
  String _getStepTitle() {
    switch (widget.tool.type) {
      case ToolType.merge:
        return 'Select PDFs to Merge';
      case ToolType.split:
        return 'Select PDF to Split';
      case ToolType.compress:
        return 'Select PDF to Compress';
      case ToolType.lockUnlock:
        return 'Select PDF to Lock/Unlock';
      case ToolType.imageToPdf:
        return 'Select Images to Convert';
      default:
        return 'Select Files';
    }
  }

  IconData _getSelectionIcon() {
    switch (widget.tool.type) {
      case ToolType.imageToPdf:
        return Icons.photo_library_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }

  String _getSelectionButtonText() {
    switch (widget.tool.type) {
      case ToolType.merge:
        return 'Choose Multiple PDFs';
      case ToolType.imageToPdf:
        return 'Choose Images';
      default:
        return 'Choose PDF File';
    }
  }

  String _getFileFormatInfo() {
    switch (widget.tool.type) {
      case ToolType.imageToPdf:
        return 'Supported formats: JPG, PNG, WEBP, BMP';
      default:
        return 'Only PDF files are supported';
    }
  }

  IconData _getActionIcon() {
    return widget.tool.icon;
  }

  String _getActionButtonText() {
    switch (widget.tool.type) {
      case ToolType.merge:
        return 'Merge PDFs';
      case ToolType.split:
        return 'Split PDF';
      case ToolType.compress:
        return 'Compress PDF';
      case ToolType.lockUnlock:
        return 'Lock/Unlock PDF';
      case ToolType.imageToPdf:
        return 'Convert to PDF';
      default:
        return 'Process';
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result;
      
      if (widget.tool.type == ToolType.imageToPdf) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: widget.tool.type == ToolType.merge,
        );
      }

      if (result != null) {
        final newFiles = result!.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        
        setState(() {
          // Add new files to existing selection, avoiding duplicates
          for (final newFile in newFiles) {
            if (!_selectedFiles.any((existing) => existing.path == newFile.path)) {
              _selectedFiles.add(newFile);
            }
          }
        });
        
        // Show feedback about how many files were added
        if (newFiles.isNotEmpty) {
          final addedCount = newFiles.where((newFile) => 
            !_selectedFiles.any((existing) => existing.path == newFile.path)).length;
          if (addedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $addedCount file${addedCount == 1 ? '' : 's'}. Total: ${_selectedFiles.length}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Files already selected'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _moveFile(int from, int to) {
    setState(() {
      final file = _selectedFiles.removeAt(from);
      _selectedFiles.insert(to, file);
    });
  }

  Future<void> _processFiles() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Initializing...';
      _resultMessage = null;
      _resultStats = null;
      _resultFilePath = null;
      _splitResultFiles = null;  // Reset split results
    });

    try {
      // Make sure PDF processing service is initialized
      await PDFProcessingService.initialize();
      
      String? outputPath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      switch (widget.tool.type) {
        case ToolType.merge:
          setState(() {
            _processingMessage = 'Validating PDFs...';
          });
          
          // Validate all files first - use basic validation for now
          for (var file in _selectedFiles) {
            try {
              final info = await PDFProcessingService.getPdfInfo(file.path);
              // If native validation works, use it
              if (info != null && !info.isValid) {
                throw Exception('Cannot process PDF: ${file.path.split('/').last}. File validation failed.');
              }
            } catch (e) {
              // If native validation fails, use fallback file checks
              try {
                final fileExists = await file.exists();
                final fileSize = await file.length();
                final fileName = file.path.split('/').last.toLowerCase();
                
                if (!fileExists) {
                  throw Exception('File not found: ${file.path.split('/').last}');
                }
                if (fileSize == 0) {
                  throw Exception('File is empty: ${file.path.split('/').last}');
                }
                if (!fileName.endsWith('.pdf')) {
                  throw Exception('Invalid file type: ${file.path.split('/').last}. Only PDF files are supported.');
                }
                
                print('Using fallback validation for: ${file.path.split('/').last} (${fileSize} bytes)');
              } catch (fallbackError) {
                throw Exception('Cannot process file: ${file.path.split('/').last}. ${fallbackError.toString().replaceAll('Exception: ', '')}');
              }
            }
          }
          
          setState(() {
            _processingMessage = 'Merging ${_selectedFiles.length} PDFs...';
          });
          
          outputPath = await PDFProcessingService.mergePDFs(
            _selectedFiles,
            'merged_pdf_$timestamp.pdf',
          );
          break;
          
        case ToolType.compress:
          setState(() {
            _processingMessage = 'Compressing PDF...';
          });
          outputPath = await PDFProcessingService.compressPDF(
            _selectedFiles.first,
            'compressed_pdf_$timestamp.pdf',
          );
          break;
          
        case ToolType.split:
          setState(() {
            _processingMessage = 'Analyzing PDF structure...';
          });
          
          final inputFile = _selectedFiles.first;
          final pdfInfo = await PDFProcessingService.getPdfInfo(inputFile.path);
          
          if (pdfInfo != null && pdfInfo.pageCount > 1) {
            // Validate split page
            if (_splitPage < 1 || _splitPage >= pdfInfo.pageCount) {
              throw Exception('Invalid split page. Must be between 1 and ${pdfInfo.pageCount - 1}');
            }
            
            setState(() {
              _processingMessage = 'Splitting PDF at page $_splitPage...';
            });
            
            // Use splitAtPage which creates two files
            final outputFiles = await PDFProcessingService.splitAtPage(
              inputFile.path,
              _splitPage,
              'split_pdf_$timestamp',
            );
            
            // Store both files for split result
            _splitResultFiles = outputFiles;
            // Use the first output file as the primary result
            outputPath = outputFiles.first;
          } else {
            throw Exception('PDF must have more than 1 page to split');
          }
          break;
          
        default:
          // For other tools, create a demo output
          setState(() {
            _processingMessage = 'Processing...';
          });
          await Future.delayed(const Duration(seconds: 2));
          break;
      }

      if (mounted && outputPath != null) {
        // Special handling for split PDF (creates two files)
        if (widget.tool.type == ToolType.split && _splitResultFiles != null) {
          Map<String, String> stats = {};
          
          for (int i = 0; i < _splitResultFiles!.length; i++) {
            final file = _splitResultFiles![i];
            final fileName = file.split('/').last;
            final pdfInfo = await PDFProcessingService.getPdfInfo(file);
            
            if (pdfInfo != null) {
              final partName = i == 0 ? 'Part 1 (1-$_splitPage)' : 'Part 2 (${_splitPage + 1}+)';
              stats['$partName File'] = fileName;
              stats['$partName Size'] = PDFProcessingService.formatFileSize(pdfInfo.fileSize);
              stats['$partName Pages'] = '${pdfInfo.pageCount} pages';
            }
          }
          
          setState(() {
            _resultMessage = 'PDF split successfully into ${_splitResultFiles!.length} parts!';
            _resultStats = stats;
            _resultFilePath = outputPath;
          });
        } else {
          // Regular single file result processing
          final pdfInfo = await PDFProcessingService.getPdfInfo(outputPath);
          Map<String, String> stats;
          
          if (pdfInfo != null) {
            stats = {
              'File Size': PDFProcessingService.formatFileSize(pdfInfo.fileSize),
              'Page Count': '${pdfInfo.pageCount} pages',
              'Valid PDF': pdfInfo.isValid ? 'Yes' : 'No',
              'Output Path': outputPath.split('/').last,
            };
          } else {
            stats = await PDFProcessingService.getFileStats(outputPath);
          }
          
          setState(() {
            _resultMessage = '${widget.tool.title} completed successfully!';
            _resultStats = stats;
            _resultFilePath = outputPath;
          });
        }
        
        // Add to recent files if it's a PDF
        if (outputPath.toLowerCase().endsWith('.pdf')) {
          // You can add logic here to save to recent files
        }
      } else if (mounted) {
        setState(() {
          _resultMessage = '${widget.tool.title} completed!';
          _resultStats = {
            'Status': 'Demo mode - feature coming soon',
            'Files Processed': '${_selectedFiles.length}',
          };
        });
      }

      // Show interstitial ad after successful operation
      if (mounted) {
        final adService = Provider.of<AdService>(context, listen: false);
        await adService.showInterstitialAd();
      }

    } catch (e) {
      print('Error in _processFiles: $e');
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Handle specific error types with more helpful messages
        if (errorMessage.toLowerCase().contains('invalid pdf')) {
          errorMessage = 'PDF validation failed. The file may be corrupted or incomplete. Please try another PDF file.';
        } else if (errorMessage.toLowerCase().contains('initialization')) {
          errorMessage = 'Failed to initialize PDF processing. Please try again.';
        } else if (errorMessage.toLowerCase().contains('permission')) {
          errorMessage = 'Permission denied. Please check file permissions.';
        } else if (errorMessage.toLowerCase().contains('not found')) {
          errorMessage = 'File not found. Please select a valid file.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _processFiles(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingMessage = '';
        });
      }
    }
  }

  void _openResultFile() {
    if (_resultFilePath != null) {
      final fileName = _resultFilePath!.split('/').last;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            filePath: _resultFilePath!,
            fileName: fileName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No output file available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _shareResultFile() {
    if (_resultFilePath != null) {
      final fileName = _resultFilePath!.split('/').last;
      Share.shareXFiles(
        [XFile(_resultFilePath!)],
        text: 'Check out this PDF created with SmartPDF: $fileName',
        subject: 'SmartPDF - $fileName',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No output file available to share'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<int?> _getSelectedFilePagesCount() async {
    if (_selectedFiles.isEmpty) return null;
    
    try {
      final pdfInfo = await PDFProcessingService.getPdfInfo(_selectedFiles.first.path);
      return pdfInfo?.pageCount;
    } catch (e) {
      print('Error getting page count: $e');
      return null;
    }
  }

  bool _canProcessFiles() {
    if (_selectedFiles.isEmpty || _isProcessing) return false;
    
    // Additional validation for split PDF
    if (widget.tool.type == ToolType.split) {
      // Check if split page input is valid
      final splitPageText = _splitPageController.text.trim();
      if (splitPageText.isEmpty) return false;
      
      final splitPage = int.tryParse(splitPageText);
      if (splitPage == null || splitPage < 1) return false;
      
      // This is a basic check - the full validation happens in processing
      return true;
    }
    
    return true;
  }

  String? _getSplitPageError(int totalPages) {
    final splitPageText = _splitPageController.text.trim();
    if (splitPageText.isEmpty) return null;
    
    final splitPage = int.tryParse(splitPageText);
    if (splitPage == null) {
      return 'Please enter a valid number';
    }
    
    if (splitPage < 1) {
      return 'Page number must be at least 1';
    }
    
    if (splitPage >= totalPages) {
      return 'Page number must be less than $totalPages';
    }
    
    return null;
  }
}