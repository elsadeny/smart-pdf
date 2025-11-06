import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class PDFFileService {
  static Future<String?> pickPDFFile() async {
    try {
      // Pick PDF file - file_picker handles permissions automatically
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // Don't load file data into memory
        withReadStream: false, // Don't use read stream
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        print('Selected PDF file: $filePath');
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error picking PDF file: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  static Future<List<String>> getRecentPDFFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recentFilesDir = Directory('${directory.path}/recent_pdfs');
      
      if (!await recentFilesDir.exists()) {
        await recentFilesDir.create(recursive: true);
        return [];
      }

      final files = recentFilesDir
          .listSync()
          .where((file) => file.path.toLowerCase().endsWith('.pdf'))
          .map((file) => file.path)
          .toList();

      // Sort by modification date (most recent first)
      files.sort((a, b) {
        final aFile = File(a);
        final bFile = File(b);
        return bFile.lastModifiedSync().compareTo(aFile.lastModifiedSync());
      });

      return files;
    } catch (e) {
      print('Error getting recent PDF files: $e');
      return [];
    }
  }

  static Future<void> addToRecentFiles(String filePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recentFilesDir = Directory('${directory.path}/recent_pdfs');
      
      if (!await recentFilesDir.exists()) {
        await recentFilesDir.create(recursive: true);
      }

      final fileName = filePath.split('/').last;
      final recentFilePath = '${recentFilesDir.path}/$fileName';
      
      // Copy file to recent directory if it doesn't exist
      final originalFile = File(filePath);
      final recentFile = File(recentFilePath);
      
      if (!await recentFile.exists() && await originalFile.exists()) {
        await originalFile.copy(recentFilePath);
      }
    } catch (e) {
      print('Error adding to recent files: $e');
    }
  }

  static String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  static String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteRecentFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting recent file: $e');
    }
  }
}