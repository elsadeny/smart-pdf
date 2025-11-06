import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Flutter plugin for spdfcore PDF processing library
/// 
/// This class provides a clean Dart API for PDF operations including:
/// - Getting PDF information (page count, file size, validation)
/// - Merging multiple PDF files
/// - Splitting PDFs by page numbers
/// - Extracting single pages
class Spdfcore {
  static const MethodChannel _channel = MethodChannel('spdfcore');
  
  /// Initialize the spdfcore library
  /// Call this once before using other functions
  static Future<bool> init() async {
    final bool result = await _channel.invokeMethod('init');
    return result;
  }
  
  /// Get the number of pages in a PDF file
  /// Returns the number of pages, or -1 if error
  static Future<int> getPageCount(String filePath) async {
    final int result = await _channel.invokeMethod('getPageCount', {
      'filePath': filePath,
    });
    return result;
  }
  
  /// Get the file size of a PDF in bytes
  /// Returns file size in bytes, or -1 if error
  static Future<int> getFileSize(String filePath) async {
    final int result = await _channel.invokeMethod('getFileSize', {
      'filePath': filePath,
    });
    return result;
  }
  
  /// Validate if a file is a valid PDF
  /// Returns true if valid PDF, false otherwise
  static Future<bool> validatePdf(String filePath) async {
    final bool result = await _channel.invokeMethod('validatePdf', {
      'filePath': filePath,
    });
    return result;
  }
  
  /// Merge multiple PDF files into one
  /// Returns true if merge successful
  static Future<bool> mergeFiles(List<String> inputFiles, String outputFile) async {
    final bool result = await _channel.invokeMethod('mergeFiles', {
      'inputFiles': inputFiles,
      'outputFile': outputFile,
    });
    return result;
  }
  
  /// Split PDF by extracting specific pages
  /// [pages] should contain 1-based page numbers
  /// Returns true if split successful
  static Future<bool> splitByPages(String inputFile, List<int> pages, String outputFile) async {
    final bool result = await _channel.invokeMethod('splitByPages', {
      'inputFile': inputFile,
      'pages': pages,
      'outputFile': outputFile,
    });
    return result;
  }
  
  /// Extract a single page from PDF
  /// [pageNumber] should be 1-based
  /// Returns true if extraction successful
  static Future<bool> extractPage(String inputFile, int pageNumber, String outputFile) async {
    final bool result = await _channel.invokeMethod('extractPage', {
      'inputPath': inputFile,
      'pageNumber': pageNumber,
      'outputPath': outputFile,
    });
    return result;
  }
  
  /// Split PDF at a specific page number
  /// Creates two files: outputPrefix_part1.pdf and outputPrefix_part2.pdf
  /// [splitPage] is 1-based - pages 1 to splitPage go to part1, rest to part2
  /// Returns true if split successful
  static Future<bool> splitAtPage(String inputFile, int splitPage, String outputPrefix) async {
    final bool result = await _channel.invokeMethod('splitAtPage', {
      'inputPath': inputFile,
      'splitPage': splitPage,
      'outputPrefix': outputPrefix,
    });
    return result;
  }
  
  /// Get the library version
  static Future<String> getVersion() async {
    final String result = await _channel.invokeMethod('getVersion');
    return result;
  }
  
  /// Get comprehensive PDF information
  /// Returns a map with pageCount, fileSize, isValid, and filePath
  static Future<PdfInfo> getPdfInfo(String filePath) async {
    final result = await _channel.invokeMethod('getPdfInfo', {
      'filePath': filePath,
    });
    
    // Safely cast the result to Map<String, dynamic>
    final Map<String, dynamic> mappedResult = Map<String, dynamic>.from(result as Map);
    return PdfInfo.fromMap(mappedResult);
  }
  
  /// Cleanup library resources
  /// Call this when you're done using the library
  static Future<void> cleanup() async {
    await _channel.invokeMethod('cleanup');
  }
}

/// Data class for PDF information
class PdfInfo {
  final int pageCount;
  final int fileSize;
  final bool isValid;
  final String filePath;
  
  const PdfInfo({
    required this.pageCount,
    required this.fileSize,
    required this.isValid,
    required this.filePath,
  });
  
  factory PdfInfo.fromMap(Map<String, dynamic> map) {
    return PdfInfo(
      pageCount: map['pageCount'] as int,
      fileSize: map['fileSize'] as int,
      isValid: map['isValid'] as bool,
      filePath: map['filePath'] as String,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'pageCount': pageCount,
      'fileSize': fileSize,
      'isValid': isValid,
      'filePath': filePath,
    };
  }
  
  @override
  String toString() {
    return 'PdfInfo(pageCount: $pageCount, fileSize: $fileSize, isValid: $isValid, filePath: $filePath)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfInfo &&
        other.pageCount == pageCount &&
        other.fileSize == fileSize &&
        other.isValid == isValid &&
        other.filePath == filePath;
  }
  
  @override
  int get hashCode {
    return pageCount.hashCode ^
        fileSize.hashCode ^
        isValid.hashCode ^
        filePath.hashCode;
  }
}

/// Exception thrown when PDF operations fail
class PdfException implements Exception {
  final String message;
  final String? code;
  
  const PdfException(this.message, [this.code]);
  
  @override
  String toString() => 'PdfException: $message${code != null ? ' ($code)' : ''}';
}

/// Safe wrapper class for PDF operations that return Results
class SafeSpdfcore {
  /// Safe version of getPageCount that returns a Result
  static Future<Result<int, PdfException>> getPageCount(String filePath) async {
    try {
      final count = await Spdfcore.getPageCount(filePath);
      if (count >= 0) {
        return Result.success(count);
      } else {
        return Result.failure(PdfException('Failed to get page count for $filePath'));
      }
    } catch (e) {
      return Result.failure(PdfException('Exception: $e'));
    }
  }
  
  /// Safe version of mergeFiles that returns a Result
  static Future<Result<String, PdfException>> mergeFiles(List<String> inputFiles, String outputFile) async {
    try {
      final success = await Spdfcore.mergeFiles(inputFiles, outputFile);
      if (success) {
        return Result.success(outputFile);
      } else {
        return Result.failure(PdfException('Failed to merge files'));
      }
    } catch (e) {
      return Result.failure(PdfException('Exception: $e'));
    }
  }
  
  /// Safe version of splitByPages that returns a Result
  static Future<Result<String, PdfException>> splitByPages(String inputFile, List<int> pages, String outputFile) async {
    try {
      final success = await Spdfcore.splitByPages(inputFile, pages, outputFile);
      if (success) {
        return Result.success(outputFile);
      } else {
        return Result.failure(PdfException('Failed to split PDF'));
      }
    } catch (e) {
      return Result.failure(PdfException('Exception: $e'));
    }
  }
  
  /// Safe version of extractPage that returns a Result
  static Future<Result<String, PdfException>> extractPage(String inputFile, int pageNumber, String outputFile) async {
    try {
      final success = await Spdfcore.extractPage(inputFile, pageNumber, outputFile);
      if (success) {
        return Result.success(outputFile);
      } else {
        return Result.failure(PdfException('Failed to extract page'));
      }
    } catch (e) {
      return Result.failure(PdfException('Exception: $e'));
    }
  }
  
  /// Safe version of splitAtPage that returns a Result
  static Future<Result<String, PdfException>> splitAtPage(String inputFile, int splitPage, String outputPrefix) async {
    try {
      final success = await Spdfcore.splitAtPage(inputFile, splitPage, outputPrefix);
      if (success) {
        return Result.success('$outputPrefix (creates _part1.pdf and _part2.pdf)');
      } else {
        return Result.failure(PdfException('Failed to split PDF at page'));
      }
    } catch (e) {
      return Result.failure(PdfException('Exception: $e'));
    }
  }
}

/// Simple Result type for error handling
class Result<T, E> {
  final T? _value;
  final E? _error;
  final bool _isSuccess;
  
  const Result._(this._value, this._error, this._isSuccess);
  
  factory Result.success(T value) => Result._(value, null, true);
  factory Result.failure(E error) => Result._(null, error, false);
  
  bool get isSuccess => _isSuccess;
  bool get isFailure => !_isSuccess;
  
  T get value {
    if (_isSuccess) return _value!;
    throw StateError('Tried to get value from a failure result');
  }
  
  E get error {
    if (!_isSuccess) return _error!;
    throw StateError('Tried to get error from a success result');
  }
  
  /// Transform the success value
  Result<U, E> map<U>(U Function(T) transform) {
    if (_isSuccess) {
      return Result.success(transform(_value!));
    } else {
      return Result.failure(_error!);
    }
  }
  
  /// Transform the error value
  Result<T, U> mapError<U>(U Function(E) transform) {
    if (_isSuccess) {
      return Result.success(_value!);
    } else {
      return Result.failure(transform(_error!));
    }
  }
  
  /// Execute a function based on success/failure
  U when<U>({
    required U Function(T) success,
    required U Function(E) failure,
  }) {
    if (_isSuccess) {
      return success(_value!);
    } else {
      return failure(_error!);
    }
  }
}