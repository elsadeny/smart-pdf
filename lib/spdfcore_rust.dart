// lib/spdfcore_rust.dart
import 'bridge_generated.dart/ffi.dart' as bridge;
import 'dart:io';

/// Dart wrapper for the Rust PDF library (via flutter_rust_bridge)
class SpdfcoreRust {
  /// Get PDF page count
  Future<int> getPageCount(String filePath) async {
    return await bridge.getPageCount(filePath: filePath);
  }

  /// Get PDF file size
  Future<BigInt> getFileSize(String filePath) async {
    return await bridge.getFileSize(filePath: filePath);
  }

  /// Validate PDF
  Future<bool> validatePdf(String filePath) async {
    return await bridge.validatePdf(filePath: filePath);
  }

  /// Get comprehensive PDF information
  Future<PdfInfo> getPdfInfo(String filePath) async {
    final pageCount = await getPageCount(filePath);
    final fileSize = await getFileSize(filePath);
    final isValid = await validatePdf(filePath);
    
    return PdfInfo(
      pageCount: pageCount,
      fileSize: fileSize.toInt(),
      isValid: isValid,
      filePath: filePath,
    );
  }

  /// Merge PDFs
  Future<void> mergeFiles(List<String> inputFiles, String outputFile) async {
    await bridge.mergeFiles(inputFiles: inputFiles, outputFile: outputFile);
  }

  /// Split PDF by pages
  Future<void> splitByPages(String inputFile, List<int> pages, String outputFile) async {
    await bridge.splitByPages(inputFile: inputFile, pages: pages, outputFile: outputFile);
  }

  /// Extract a single page
  Future<void> extractPage(String inputFile, int pageNumber, String outputFile) async {
    await bridge.extractPage(inputFile: inputFile, pageNumber: pageNumber, outputFile: outputFile);
  }

  /// Split at a page (creates _part1.pdf and _part2.pdf)
  Future<List<String>> splitAtPage(String inputFile, int splitPage, String outputPrefix) async {
    await bridge.splitAtPage(inputFile: inputFile, splitPage: splitPage, outputPrefix: outputPrefix);
    
    // Return the expected output file paths
    return [
      '${outputPrefix}_part1.pdf',
      '${outputPrefix}_part2.pdf',
    ];
  }

  /// Compress PDF (placeholder - currently just copies the file)
  Future<String> compressPdf(String inputFile, String outputFile) async {
    // For now, just copy the file as compression might not be implemented in Rust yet
    final input = File(inputFile);
    await input.copy(outputFile);
    return outputFile;
  }

  /// Get library version
  Future<String> getVersion() async {
    return await bridge.spdfcoreVersion();
  }

  /// Format file size in human-readable format
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

  /// Get basic file statistics
  Future<Map<String, String>> getFileStats(String filePath) async {
    try {
      final pdfInfo = await getPdfInfo(filePath);
      return {
        'File Size': formatFileSize(pdfInfo.fileSize),
        'Page Count': '${pdfInfo.pageCount} pages',
        'Valid PDF': pdfInfo.isValid ? 'Yes' : 'No',
        'File Name': filePath.split('/').last,
      };
    } catch (e) {
      final file = File(filePath);
      final stats = await file.stat();
      return {
        'File Size': formatFileSize(stats.size),
        'File Name': filePath.split('/').last,
        'Error': 'Could not read PDF info',
      };
    }
  }
}

/// PDF information class
class PdfInfo {
  final int pageCount;
  final int fileSize;
  final bool isValid;
  final String filePath;

  PdfInfo({
    required this.pageCount,
    required this.fileSize,
    required this.isValid,
    required this.filePath,
  });
}
