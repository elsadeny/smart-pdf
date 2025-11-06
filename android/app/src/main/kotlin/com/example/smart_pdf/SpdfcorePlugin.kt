package com.example.smart_pdf

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter Plugin for spdfcore PDF processing library
 * 
 * This plugin provides a bridge between Flutter/Dart and the native spdfcore library
 * Handles method channel communication and native library operations
 */
class SpdfcorePlugin: FlutterPlugin, MethodCallHandler {
    
    companion object {
        private const val CHANNEL = "spdfcore"
        private var isNativeLibraryLoaded = false
        
        // Load the native library
        init {
            try {
                android.util.Log.i("SpdfcorePlugin", "Attempting to load spdfcore_ffi library...")
                System.loadLibrary("spdfcore_ffi")
                android.util.Log.i("SpdfcorePlugin", "Successfully loaded spdfcore_ffi library")
                
                android.util.Log.i("SpdfcorePlugin", "Attempting to load spdfcore library...")
                System.loadLibrary("spdfcore")
                isNativeLibraryLoaded = true
                android.util.Log.i("SpdfcorePlugin", "Successfully loaded spdfcore library")
            } catch (e: UnsatisfiedLinkError) {
                isNativeLibraryLoaded = false
                android.util.Log.e("SpdfcorePlugin", "Failed to load libraries: ${e.message}")
                android.util.Log.e("SpdfcorePlugin", "UnsatisfiedLinkError details: ${e.stackTraceToString()}")
            } catch (e: Exception) {
                isNativeLibraryLoaded = false
                android.util.Log.e("SpdfcorePlugin", "Unexpected error loading library: ${e.message}")
            }
        }
    }
    
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    // Native function declarations
    private external fun nativeInit(): Boolean
    private external fun nativeGetPageCount(filePath: String): Int
    private external fun nativeValidateFile(filePath: String): Boolean
    private external fun nativeMergeFiles(inputFiles: Array<String>, outputFile: String): Boolean
    private external fun nativeGetFileSize(filePath: String): Long
    private external fun nativeExtractPage(inputPath: String, pageNumber: Int, outputPath: String): Boolean
    private external fun nativeSplitAtPage(inputPath: String, splitPage: Int, outputPrefix: String): Boolean
    private external fun nativeGetVersion(): String
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Don't call nativeInit here - let the Dart code call it explicitly via method channel
        android.util.Log.i("SpdfcorePlugin", "Plugin attached, isNativeLibraryLoaded: $isNativeLibraryLoaded")
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            // If native library is not loaded, provide fallback implementations
            if (!isNativeLibraryLoaded) {
                when (call.method) {
                    "init" -> {
                        result.success(false) // Indicate native library not available
                    }
                    "validatePdf" -> {
                        // Basic file validation fallback
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            val file = java.io.File(filePath)
                            val isValid = file.exists() && file.length() > 0 && filePath.lowercase().endsWith(".pdf")
                            result.success(isValid)
                        } else {
                            result.error("INVALID_ARGUMENT", "filePath is required", null)
                        }
                    }
                    "getPdfInfo" -> {
                        // Basic file info fallback
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            val file = java.io.File(filePath)
                            val fileSizeLong = file.length()
                            val fileSize = if (fileSizeLong > Int.MAX_VALUE) Int.MAX_VALUE else fileSizeLong.toInt()
                            val info = mapOf<String, Any>(
                                "pageCount" to -1, // Unknown without native library
                                "fileSize" to fileSize,
                                "isValid" to (file.exists() && file.length() > 0 && filePath.lowercase().endsWith(".pdf")),
                                "filePath" to filePath
                            )
                            result.success(info)
                        } else {
                            result.error("INVALID_ARGUMENT", "filePath is required", null)
                        }
                    }
                    else -> {
                        result.error("NATIVE_LIBRARY_UNAVAILABLE", "Native library not loaded, operation not supported", null)
                    }
                }
                return
            }
            
            when (call.method) {
                "init" -> {
                    android.util.Log.i("SpdfcorePlugin", "Init called, isNativeLibraryLoaded: $isNativeLibraryLoaded")
                    val success = if (isNativeLibraryLoaded) {
                        try {
                            android.util.Log.i("SpdfcorePlugin", "Calling nativeInit...")
                            val initResult = nativeInit()
                            android.util.Log.i("SpdfcorePlugin", "nativeInit returned: $initResult")
                            initResult
                        } catch (e: UnsatisfiedLinkError) {
                            android.util.Log.e("SpdfcorePlugin", "UnsatisfiedLinkError in nativeInit: ${e.message}")
                            android.util.Log.e("SpdfcorePlugin", "Full exception: ${e.stackTraceToString()}")
                            false
                        } catch (e: Exception) {
                            android.util.Log.e("SpdfcorePlugin", "Exception in nativeInit: ${e.message}")
                            android.util.Log.e("SpdfcorePlugin", "Full exception: ${e.stackTraceToString()}")
                            false
                        }
                    } else {
                        android.util.Log.w("SpdfcorePlugin", "Native library not loaded, returning false")
                        false
                    }
                    android.util.Log.i("SpdfcorePlugin", "Init result: $success")
                    result.success(success)
                }
                
                "getPageCount" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val pageCount = if (isNativeLibraryLoaded) {
                            try {
                                nativeGetPageCount(filePath)
                            } catch (e: UnsatisfiedLinkError) {
                                -1
                            }
                        } else {
                            -1
                        }
                        result.success(pageCount)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                
                "getFileSize" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            val fileSize = nativeGetFileSize(filePath)
                            if (fileSize >= 0) {
                                result.success(fileSize)
                            } else {
                                result.error("FILE_ERROR", "Failed to get file size", null)
                            }
                        } catch (e: Exception) {
                            Log.e("SpdfcorePlugin", "Error getting file size: ${e.message}")
                            // Fallback to Java File.length()
                            val fileSize = java.io.File(filePath).length()
                            result.success(fileSize)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                
                "validatePdf" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val isValid = nativeValidateFile(filePath)
                        result.success(isValid)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                
                "mergeFiles" -> {
                    val inputFiles = call.argument<List<String>>("inputFiles")
                    val outputFile = call.argument<String>("outputFile")
                    
                    if (inputFiles != null && outputFile != null) {
                        val success = if (isNativeLibraryLoaded) {
                            try {
                                nativeMergeFiles(inputFiles.toTypedArray(), outputFile)
                            } catch (e: UnsatisfiedLinkError) {
                                false
                            }
                        } else {
                            false
                        }
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "inputFiles and outputFile are required", null)
                    }
                }
                
                "splitByPages" -> {
                    // Not implemented yet, return false
                    result.success(false)
                }
                
                "extractPage" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val pageNumber = call.argument<Int>("pageNumber")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (inputPath != null && pageNumber != null && outputPath != null) {
                        try {
                            val success = nativeExtractPage(inputPath, pageNumber, outputPath)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.e("SpdfcorePlugin", "Error extracting page: ${e.message}")
                            result.error("EXTRACT_ERROR", "Failed to extract page: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "inputPath, pageNumber, and outputPath are required", null)
                    }
                }
                
                "splitAtPage" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val splitPage = call.argument<Int>("splitPage")
                    val outputPrefix = call.argument<String>("outputPrefix")
                    
                    if (inputPath != null && splitPage != null && outputPrefix != null) {
                        try {
                            val success = nativeSplitAtPage(inputPath, splitPage, outputPrefix)
                            result.success(success)
                        } catch (e: Exception) {
                            Log.e("SpdfcorePlugin", "Error splitting PDF at page: ${e.message}")
                            result.error("SPLIT_ERROR", "Failed to split PDF at page: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "inputPath, splitPage, and outputPrefix are required", null)
                    }
                }
                
                "getVersion" -> {
                    try {
                        val version = nativeGetVersion()
                        result.success(version)
                    } catch (e: Exception) {
                        Log.e("SpdfcorePlugin", "Error getting version: ${e.message}")
                        // Fallback to hardcoded version
                        result.success("1.0.0")
                    }
                }
                
                "cleanup" -> {
                    // No cleanup needed for current implementation
                    result.success(null)
                }
                
                "getPdfInfo" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val info = if (isNativeLibraryLoaded) {
                            try {
                                val pageCount = nativeGetPageCount(filePath)
                                val fileSize = nativeGetFileSize(filePath)
                                val isValid = nativeValidateFile(filePath)
                                
                                Log.i("SpdfcorePlugin", "Native getPdfInfo: pageCount=$pageCount, fileSize=$fileSize, isValid=$isValid")
                                
                                mapOf<String, Any>(
                                    "pageCount" to pageCount,
                                    "fileSize" to fileSize,
                                    "isValid" to isValid,
                                    "filePath" to filePath
                                )
                            } catch (e: UnsatisfiedLinkError) {
                                Log.e("SpdfcorePlugin", "Native library error in getPdfInfo", e)
                                // Fallback to basic file info
                                val file = java.io.File(filePath)
                                val fileSize = file.length()
                                mapOf<String, Any>(
                                    "pageCount" to -1,
                                    "fileSize" to fileSize,
                                    "isValid" to (file.exists() && file.length() > 0 && filePath.lowercase().endsWith(".pdf")),
                                    "filePath" to filePath
                                )
                            } catch (e: Exception) {
                                Log.e("SpdfcorePlugin", "Error in getPdfInfo", e)
                                // Fallback to basic file info
                                val file = java.io.File(filePath)
                                val fileSize = file.length()
                                mapOf<String, Any>(
                                    "pageCount" to -1,
                                    "fileSize" to fileSize,
                                    "isValid" to (file.exists() && file.length() > 0 && filePath.lowercase().endsWith(".pdf")),
                                    "filePath" to filePath
                                )
                            }
                        } else {
                            // Fallback to basic file info
                            val file = java.io.File(filePath)
                            val fileSize = file.length()
                            mapOf<String, Any>(
                                "pageCount" to -1,
                                "fileSize" to fileSize,
                                "isValid" to (file.exists() && file.length() > 0 && filePath.lowercase().endsWith(".pdf")),
                                "filePath" to filePath
                            )
                        }
                        result.success(info)
                    } else {
                        result.error("INVALID_ARGUMENT", "filePath is required", null)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
        }
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // No cleanup needed for current implementation
    }
}