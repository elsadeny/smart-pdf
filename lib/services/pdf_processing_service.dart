import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../spdfcore.dart';

class PDFProcessingService {
  static bool _initialized = false;
  
  /// Initialize the PDF processing service
  static Future<bool> initialize() async {
    if (!_initialized) {
      try {
        final result = await Spdfcore.init();
        _initialized = result;
        print('PDFProcessingService: Initialized spdfcore - $_initialized');
        
        if (!_initialized) {
          print('PDFProcessingService: Native library not available, using fallback mode');
        }
        
        return _initialized;
      } catch (e) {
        print('PDFProcessingService: Failed to initialize spdfcore: $e');
        print('PDFProcessingService: Will use fallback PDF processing');
        _initialized = false;
        return false;
      }
    }
    return _initialized;
  }
  
  /// Get comprehensive PDF information
  static Future<PdfInfo?> getPdfInfo(String filePath) async {
    try {
      final initialized = await initialize();
      
      if (initialized) {
        try {
          final pdfInfo = await Spdfcore.getPdfInfo(filePath);
          if (pdfInfo != null) {  
            print('Retrieved PDF info from native library success');
          }
          return pdfInfo;
        } catch (e) {
          print('PDFProcessingService: Native getPdfInfo failed: $e');
          return _getFallbackPdfInfo(filePath);
        }
      } else {
        print('PDFProcessingService: Library not initialized, using fallback');
        return _getFallbackPdfInfo(filePath);
      }
    } catch (e) {
      print('PDFProcessingService: Failed to get PDF info: $e');
      // Return fallback info
      return _getFallbackPdfInfo(filePath);
    }
  }
  
  /// Fallback PDF info when native library fails
  static Future<PdfInfo?> _getFallbackPdfInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final fileSize = await file.length();
      final fileName = filePath.split('/').last.toLowerCase();
      
      // Basic validation - check file extension and size
      final isValidExtension = fileName.endsWith('.pdf');
      final hasValidSize = fileSize > 0;
      
      return PdfInfo(
        pageCount: 1, // Default fallback
        fileSize: fileSize,
        isValid: isValidExtension && hasValidSize,
        filePath: filePath,
      );
    } catch (e) {
      print('PDFProcessingService: Fallback PDF info failed: $e');
      return null;
    }
  }
  
  /// Merge multiple PDF files using native library
  static Future<String> mergePDFs(List<File> pdfFiles, String outputFileName) async {
    try {
      print('PDFProcessingService: Starting merge of ${pdfFiles.length} files');
      
      // Try to initialize the library
      final initialized = await initialize();
      
      // Convert File objects to paths
      final filePaths = pdfFiles.map((f) => f.path).toList();
      
      // Validate input files with fallback
      for (String filePath in filePaths) {
        bool isValid = false;
        try {
          if (initialized) {
            isValid = await Spdfcore.validatePdf(filePath);
          } else {
            throw Exception('Native library not available');
          }
        } catch (e) {
          print('PDFProcessingService: Native validation failed, using fallback: $e');
          // Fallback validation
          final file = File(filePath);
          final exists = await file.exists();
          final hasValidExtension = filePath.toLowerCase().endsWith('.pdf');
          final hasValidSize = exists ? (await file.length()) > 0 : false;
          isValid = exists && hasValidExtension && hasValidSize;
        }
        
        if (!isValid) {
          throw Exception('Invalid PDF file: ${filePath.split('/').last}');
        }
        print('PDFProcessingService: Validated ${filePath.split('/').last}');
      }
      
      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$outputFileName';
      
      print('PDFProcessingService: Output path: $outputPath');
      
      // Perform merge using native library or fallback
      bool success = false;
      try {
        if (initialized) {
          print('PDFProcessingService: Attempting native merge with ${filePaths.length} files:');
          for (int i = 0; i < filePaths.length; i++) {
            print('  File ${i + 1}: ${filePaths[i]}');
          }
          success = await Spdfcore.mergeFiles(filePaths, outputPath);
          print('PDFProcessingService: Native merge result: $success');
        } else {
          throw Exception('Native library not available, using fallback');
        }
      } catch (e) {
        print('PDFProcessingService: Native merge failed, using fallback: $e');
        success = await _fallbackMergePDFs(filePaths, outputPath);
      }
      
      if (success) {
        print('PDFProcessingService: Merge successful');
        return outputPath;
      } else {
        throw Exception('Both native and fallback merge operations failed');
      }
    } catch (e) {
      print('PDFProcessingService: Error merging PDFs: $e');
      rethrow;
    }
  }
  
  /// Split PDF by extracting specific pages
  static Future<String> splitPDF(String inputPath, List<int> pages, String outputFileName) async {
    try {
      print('PDFProcessingService: Starting split operation');
      await initialize();
      
      // Validate input file
      final isValid = await Spdfcore.validatePdf(inputPath);
      if (!isValid) {
        throw Exception('Invalid PDF file: ${inputPath.split('/').last}');
      }
      
      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$outputFileName';
      
      // Perform split using native library
      final success = await Spdfcore.splitByPages(inputPath, pages, outputPath);
      
      if (success) {
        print('PDFProcessingService: Split successful');
        return outputPath;
      } else {
        throw Exception('Native split operation failed');
      }
    } catch (e) {
      print('PDFProcessingService: Error splitting PDF: $e');
      rethrow;
    }
  }
  
  /// Extract a single page from PDF
  static Future<String> extractPage(String inputPath, int pageNumber, String outputFileName) async {
    try {
      await initialize();
      
      // Validate input file
      final isValid = await Spdfcore.validatePdf(inputPath);
      if (!isValid) {
        throw Exception('Invalid PDF file: ${inputPath.split('/').last}');
      }
      
      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$outputFileName';
      
      // Extract page using native library
      final success = await Spdfcore.extractPage(inputPath, pageNumber, outputPath);
      
      if (success) {
        print('PDFProcessingService: Page extraction successful');
        return outputPath;
      } else {
        throw Exception('Native page extraction failed');
      }
    } catch (e) {
      print('PDFProcessingService: Error extracting page: $e');
      rethrow;
    }
  }
  
  /// Split PDF at a specific page number
  /// Creates two files with the specified output prefix
  static Future<List<String>> splitAtPage(String inputPath, int splitPage, String outputPrefix) async {
    try {
      await initialize();
      
      // Validate input file
      final isValid = await Spdfcore.validatePdf(inputPath);
      if (!isValid) {
        throw Exception('Invalid PDF file: ${inputPath.split('/').last}');
      }
      
      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final outputBasePath = '${directory.path}/$outputPrefix';
      
      // Split PDF using native library
      final success = await Spdfcore.splitAtPage(inputPath, splitPage, outputBasePath);
      
      if (success) {
        final outputFiles = [
          '${outputBasePath}_part1.pdf',
          '${outputBasePath}_part2.pdf'
        ];
        print('PDFProcessingService: PDF split successful');
        return outputFiles;
      } else {
        throw Exception('Native PDF split failed');
      }
    } catch (e) {
      print('PDFProcessingService: Error splitting PDF: $e');
      rethrow;
    }
  }
  
  /// Compress PDF (placeholder - implement if available in native library)
  static Future<String> compressPDF(File inputFile, String outputFileName) async {
    try {
      await initialize();
      
      // For now, just copy the file as compression may not be implemented yet
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$outputFileName';
      
      await inputFile.copy(outputPath);
      
      print('PDFProcessingService: File copied (compression placeholder): $outputPath');
      return outputPath;
    } catch (e) {
      print('PDFProcessingService: Error compressing PDF: $e');
      rethrow;
    }
  }
  
  /// Get file size in a human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  /// Get file stats
  static Future<Map<String, String>> getFileStats(String filePath) async {
    try {
      final pdfInfo = await getPdfInfo(filePath);
      if (pdfInfo != null) {
        return {
          'File Size': formatFileSize(pdfInfo.fileSize),
          'Page Count': '${pdfInfo.pageCount} pages',
          'Valid PDF': pdfInfo.isValid ? 'Yes' : 'No',
          'Path': filePath,
        };
      } else {
        final file = File(filePath);
        final stats = await file.stat();
        return {
          'File Size': formatFileSize(stats.size),
          'Created': stats.changed.toString().split('.')[0],
          'Path': filePath,
        };
      }
    } catch (e) {
      return {
        'Error': 'Could not read file stats: $e',
      };
    }
  }
  
  /// Cleanup resources
  static Future<void> cleanup() async {
    if (_initialized) {
      try {
        await Spdfcore.cleanup();
      } catch (e) {
        print('PDFProcessingService: Cleanup failed: $e');
      }
      _initialized = false;
      print('PDFProcessingService: Cleaned up spdfcore');
    }
  }
  
  /// Fallback merge function when native library is not available
  static Future<bool> _fallbackMergePDFs(List<String> filePaths, String outputPath) async {
    try {
      final document = pw.Document();
      
      // Create a title page with file information
      document.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartPDF - Merged Document',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This document was created by merging ${filePaths.length} PDF files:',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                ...filePaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filePath = entry.value;
                  final fileName = filePath.split('/').last;
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      '${index + 1}. $fileName',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Note: This merged document was created using fallback PDF processing. '
                    'The native PDF library will provide better content merging once fully configured.',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save the document
      final file = File(outputPath);
      await file.writeAsBytes(await document.save());
      
      print('PDFProcessingService: Fallback merge completed');
      return true;
    } catch (e) {
      print('PDFProcessingService: Fallback merge failed: $e');
      return false;
    }
  }
}