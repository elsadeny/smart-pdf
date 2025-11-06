#include <jni.h>
#include <string>
#include <vector>
#include <memory>
#include <android/log.h>
#include <dlfcn.h>
#include "spdfcore.h"  // Include the official header

#define LOG_TAG "SpdfcoreNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Function pointer types matching the generated spdfcore.h
typedef bool (*pdf_merge_files_func)(const char* const* input_paths, size_t path_count, const char* output_path, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_validate_func)(const char* file_path, bool* is_valid, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_get_page_count_func)(const char* file_path, int32_t* page_count, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_get_file_size_func)(const char* file_path, uint64_t* file_size, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_split_by_pages_func)(const char* input_path, const int32_t* pages, size_t page_count, const char* output_path, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_extract_page_func)(const char* input_path, int32_t page_number, const char* output_path, PdfErrorCode* error_code, char** error_message);
typedef bool (*pdf_split_at_page_func)(const char* input_path, int32_t split_page, const char* output_prefix, PdfErrorCode* error_code, char** error_message);
typedef const char* (*spdfcore_version_func)(void);
typedef void (*free_c_string_func)(char* str);

// Global function pointers
static pdf_merge_files_func pdf_merge_files_ptr = nullptr;
static pdf_validate_func pdf_validate_ptr = nullptr;
static pdf_get_page_count_func pdf_get_page_count_ptr = nullptr;
static pdf_get_file_size_func pdf_get_file_size_ptr = nullptr;
static pdf_split_by_pages_func pdf_split_by_pages_ptr = nullptr;
static pdf_extract_page_func pdf_extract_page_ptr = nullptr;
static pdf_split_at_page_func pdf_split_at_page_ptr = nullptr;
static spdfcore_version_func spdfcore_version_ptr = nullptr;
static free_c_string_func free_c_string_ptr = nullptr;
static void* spdfcore_ffi_handle = nullptr;

// Initialize the dynamic library
static bool init_spdfcore_ffi() {
    if (spdfcore_ffi_handle != nullptr) {
        return true; // Already initialized
    }
    
    LOGI("Loading spdfcore_ffi library dynamically...");
    spdfcore_ffi_handle = dlopen("libspdfcore_ffi.so", RTLD_LAZY);
    if (!spdfcore_ffi_handle) {
        LOGE("Cannot load spdfcore_ffi library: %s", dlerror());
        return false;
    }
    
    // Load function pointers
    pdf_merge_files_ptr = (pdf_merge_files_func)dlsym(spdfcore_ffi_handle, "pdf_merge_files");
    if (!pdf_merge_files_ptr) {
        LOGE("Cannot load pdf_merge_files: %s", dlerror());
        dlclose(spdfcore_ffi_handle);
        spdfcore_ffi_handle = nullptr;
        return false;
    }
    
    pdf_validate_ptr = (pdf_validate_func)dlsym(spdfcore_ffi_handle, "pdf_validate");
    if (!pdf_validate_ptr) {
        LOGE("Cannot load pdf_validate: %s", dlerror());
        dlclose(spdfcore_ffi_handle);
        spdfcore_ffi_handle = nullptr;
        return false;
    }
    
    pdf_get_page_count_ptr = (pdf_get_page_count_func)dlsym(spdfcore_ffi_handle, "pdf_get_page_count");
    if (!pdf_get_page_count_ptr) {
        LOGE("Cannot load pdf_get_page_count: %s", dlerror());
        dlclose(spdfcore_ffi_handle);
        spdfcore_ffi_handle = nullptr;
        return false;
    }
    
    free_c_string_ptr = (free_c_string_func)dlsym(spdfcore_ffi_handle, "free_c_string");
    if (!free_c_string_ptr) {
        LOGE("Cannot load free_c_string: %s", dlerror());
        dlclose(spdfcore_ffi_handle);
        spdfcore_ffi_handle = nullptr;
        return false;
    }
    
    // Load new optional functions (don't fail if they're not available for backward compatibility)
    pdf_get_file_size_ptr = (pdf_get_file_size_func)dlsym(spdfcore_ffi_handle, "pdf_get_file_size");
    if (!pdf_get_file_size_ptr) {
        LOGI("pdf_get_file_size not available in this version");
    }
    
    pdf_split_by_pages_ptr = (pdf_split_by_pages_func)dlsym(spdfcore_ffi_handle, "pdf_split_by_pages");
    if (!pdf_split_by_pages_ptr) {
        LOGI("pdf_split_by_pages not available in this version");
    }
    
    pdf_extract_page_ptr = (pdf_extract_page_func)dlsym(spdfcore_ffi_handle, "pdf_extract_page");
    if (!pdf_extract_page_ptr) {
        LOGI("pdf_extract_page not available in this version");
    }
    
    pdf_split_at_page_ptr = (pdf_split_at_page_func)dlsym(spdfcore_ffi_handle, "pdf_split_at_page");
    if (!pdf_split_at_page_ptr) {
        LOGI("pdf_split_at_page not available in this version");
    }
    
    spdfcore_version_ptr = (spdfcore_version_func)dlsym(spdfcore_ffi_handle, "spdfcore_version");
    if (!spdfcore_version_ptr) {
        LOGI("spdfcore_version not available in this version");
    }
    
    LOGI("Successfully loaded all spdfcore_ffi functions");
    return true;
}

// Helper function to convert Java string array to C string array
std::vector<std::string> jstringArrayToVector(JNIEnv* env, jobjectArray jarray) {
    std::vector<std::string> result;
    jsize length = env->GetArrayLength(jarray);
    
    for (jsize i = 0; i < length; i++) {
        jstring jstr = (jstring)env->GetObjectArrayElement(jarray, i);
        const char* str = env->GetStringUTFChars(jstr, nullptr);
        result.push_back(std::string(str));
        env->ReleaseStringUTFChars(jstr, str);
        env->DeleteLocalRef(jstr);
    }
    
    return result;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeInit(JNIEnv *env, jobject /* this */) {
    LOGI("nativeInit called");
    bool success = init_spdfcore_ffi();
    LOGI("nativeInit returning: %s", success ? "true" : "false");
    return success ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeMergeFiles(JNIEnv *env, jobject /* this */,
                                                    jobjectArray inputPaths,
                                                    jstring outputPath) {
    LOGI("nativeMergeFiles called");
    LOGI("====== MERGE FILES PARAMETERS ======");
    
    if (!pdf_merge_files_ptr) {
        LOGE("pdf_merge_files_ptr is null - library not initialized");
        return JNI_FALSE;
    }
    
    // Log raw Java parameters
    jsize inputArrayLength = env->GetArrayLength(inputPaths);
    LOGI("Raw Java inputPaths array length: %d", inputArrayLength);
    
    // Convert Java strings to C strings
    std::vector<std::string> inputPathsVec = jstringArrayToVector(env, inputPaths);
    const char* outputPathStr = env->GetStringUTFChars(outputPath, nullptr);
    
    LOGI("Converted input count: %zu", inputPathsVec.size());
    LOGI("Output path: %s", outputPathStr);
    LOGI("Output path length: %zu", strlen(outputPathStr));
    
    // Convert vector to array of const char*
    std::vector<const char*> inputPathsArray;
    LOGI("====== INPUT FILES ANALYSIS ======");
    for (size_t i = 0; i < inputPathsVec.size(); i++) {
        const auto& path = inputPathsVec[i];
        inputPathsArray.push_back(path.c_str());
        LOGI("Input file %zu:", i + 1);
        LOGI("  Path: %s", path.c_str());
        LOGI("  Path length: %zu", path.length());
        LOGI("  C string pointer: %p", path.c_str());
        
        // Debug: Check individual file sizes
        if (pdf_get_file_size_ptr) {
            uint64_t file_size = 0;
            PdfErrorCode size_error = PdfErrorCode_Success;
            char* size_error_msg = nullptr;
            bool size_result = pdf_get_file_size_ptr(path.c_str(), &file_size, &size_error, &size_error_msg);
            if (size_result && size_error == PdfErrorCode_Success) {
                LOGI("  File size: %llu bytes", file_size);
            } else {
                LOGI("  File size check failed: error_code=%d", size_error);
                if (size_error_msg) {
                    LOGI("  Size error: %s", size_error_msg);
                    free_c_string_ptr(size_error_msg);
                }
            }
        } else {
            LOGI("  File size check not available");
        }
    }
    
    // Call the Rust function via function pointer with correct signature
    LOGI("====== CALLING NATIVE MERGE FUNCTION ======");
    LOGI("Function pointer: %p", (void*)pdf_merge_files_ptr);
    LOGI("Input paths array pointer: %p", (void*)inputPathsArray.data());
    LOGI("Input paths array size: %zu", inputPathsArray.size());
    LOGI("Output path pointer: %p", (void*)outputPathStr);
    LOGI("Calling pdf_merge_files...");
    
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_merge_files_ptr(inputPathsArray.data(), 
                                      inputPathsArray.size(), 
                                      outputPathStr,
                                      &error_code,
                                      &error_message);
    
    LOGI("====== MERGE FUNCTION RESULT ======");
    LOGI("pdf_merge_files returned: %s", result ? "true" : "false");
    LOGI("Error code: %d", error_code);
    if (error_message) {
        LOGI("Error message: %s", error_message);
        LOGI("Error message length: %zu", strlen(error_message));
        free_c_string_ptr(error_message);
    } else {
        LOGI("No error message");
    }
    
    // Debug: Check output file size after merge
    LOGI("====== OUTPUT FILE VERIFICATION ======");
    if (result && error_code == PdfErrorCode_Success && pdf_get_file_size_ptr) {
        uint64_t output_file_size = 0;
        PdfErrorCode output_size_error = PdfErrorCode_Success;
        char* output_size_error_msg = nullptr;
        bool output_size_result = pdf_get_file_size_ptr(outputPathStr, &output_file_size, &output_size_error, &output_size_error_msg);
        if (output_size_result && output_size_error == PdfErrorCode_Success) {
            LOGI("Merged output file size: %llu bytes", output_file_size);
            
            // Calculate expected total size from input files
            uint64_t total_input_size = 0;
            for (size_t i = 0; i < inputPathsVec.size(); i++) {
                uint64_t file_size = 0;
                PdfErrorCode size_error = PdfErrorCode_Success;
                char* size_error_msg = nullptr;
                bool size_result = pdf_get_file_size_ptr(inputPathsVec[i].c_str(), &file_size, &size_error, &size_error_msg);
                if (size_result && size_error == PdfErrorCode_Success) {
                    total_input_size += file_size;
                }
                if (size_error_msg) {
                    free_c_string_ptr(size_error_msg);
                }
            }
            LOGI("Total input files size: %llu bytes", total_input_size);
            LOGI("Size difference: %lld bytes", (int64_t)output_file_size - (int64_t)total_input_size);
            
            if (output_file_size == total_input_size) {
                LOGI("WARNING: Output size equals total input size - possible merge failure");
            } else if (output_file_size < total_input_size) {
                LOGI("WARNING: Output size smaller than input - possible merge failure");
            } else {
                LOGI("Output size larger than input - merge appears successful");
            }
        } else {
            LOGI("Failed to get merged output file size: error_code=%d", output_size_error);
            if (output_size_error_msg) {
                LOGI("Output size error: %s", output_size_error_msg);
                free_c_string_ptr(output_size_error_msg);
            }
        }
    } else {
        if (!result) {
            LOGI("Skipping output verification - merge function failed");
        } else if (error_code != PdfErrorCode_Success) {
            LOGI("Skipping output verification - error code: %d", error_code);
        } else if (!pdf_get_file_size_ptr) {
            LOGI("Skipping output verification - file size function not available");
        }
    }
    
    // Clean up
    env->ReleaseStringUTFChars(outputPath, outputPathStr);
    
    bool success = result && (error_code == PdfErrorCode_Success);
    LOGI("====== FINAL RESULT ======");
    LOGI("Function result: %s", result ? "true" : "false");
    LOGI("Error code: %d", error_code);
    LOGI("Success condition: %s", success ? "true" : "false");
    LOGI("Returning to Java: %s", success ? "JNI_TRUE" : "JNI_FALSE");
    LOGI("====== END MERGE FILES ======");
    return success ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeValidateFile(JNIEnv *env, jobject /* this */,
                                                      jstring filePath) {
    LOGI("nativeValidateFile called");
    
    if (!pdf_validate_ptr) {
        LOGE("pdf_validate_ptr is null - library not initialized");
        return JNI_FALSE;
    }
    
    const char* filePathStr = env->GetStringUTFChars(filePath, nullptr);
    LOGI("Validating file: %s", filePathStr);
    
    // Check if file exists first
    FILE* file = fopen(filePathStr, "r");
    if (!file) {
        LOGE("File does not exist or cannot be opened: %s", filePathStr);
        env->ReleaseStringUTFChars(filePath, filePathStr);
        return JNI_FALSE;
    }
    fclose(file);
    LOGI("File exists and can be opened");
    
    // Call the Rust function with correct signature from spdfcore.h
    bool is_valid = false;
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_validate_ptr(filePathStr, &is_valid, &error_code, &error_message);
    
    LOGI("pdf_validate returned: %s, is_valid: %s, error_code: %d", 
         result ? "true" : "false", 
         is_valid ? "true" : "false", 
         error_code);
    
    if (error_message) {
        LOGI("Error message: %s", error_message);
        free_c_string_ptr(error_message);
    }
    
    env->ReleaseStringUTFChars(filePath, filePathStr);
    
    bool success = result && is_valid && (error_code == PdfErrorCode_Success);
    LOGI("nativeValidateFile returning: %s", success ? "true" : "false");
    return success ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeGetPageCount(JNIEnv *env, jobject /* this */,
                                                      jstring filePath) {
    LOGI("nativeGetPageCount called");
    
    if (!pdf_get_page_count_ptr) {
        LOGE("pdf_get_page_count_ptr is null - library not initialized");
        return -1;
    }
    
    const char* filePathStr = env->GetStringUTFChars(filePath, nullptr);
    LOGI("Getting page count for file: %s", filePathStr);
    
    // Call the Rust function with correct signature from spdfcore.h
    int32_t page_count = 0;
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_get_page_count_ptr(filePathStr, &page_count, &error_code, &error_message);
    
    LOGI("pdf_get_page_count returned: %s, page_count: %d, error_code: %d", 
         result ? "true" : "false", 
         page_count, 
         error_code);
    
    if (error_message) {
        LOGI("Error message: %s", error_message);
        free_c_string_ptr(error_message);
    }
    
    env->ReleaseStringUTFChars(filePath, filePathStr);
    
    if (result && error_code == PdfErrorCode_Success) {
        return page_count;
    } else {
        LOGE("Failed to get page count, error: %d", error_code);
        return -1;
    }
}

extern "C"
JNIEXPORT jlong JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeGetFileSize(JNIEnv *env, jobject /* this */,
                                                      jstring filePath) {
    LOGI("nativeGetFileSize called");
    
    if (!pdf_get_file_size_ptr) {
        LOGE("pdf_get_file_size_ptr is null - function not available");
        return -1;
    }
    
    const char* filePathStr = env->GetStringUTFChars(filePath, nullptr);
    LOGI("Getting file size for: %s", filePathStr);
    
    uint64_t file_size = 0;
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_get_file_size_ptr(filePathStr, &file_size, &error_code, &error_message);
    
    LOGI("pdf_get_file_size returned: %s, file_size: %llu, error_code: %d", 
         result ? "true" : "false", 
         file_size, 
         error_code);
    
    if (error_message) {
        LOGI("Error message: %s", error_message);
        free_c_string_ptr(error_message);
    }
    
    env->ReleaseStringUTFChars(filePath, filePathStr);
    
    if (result && error_code == PdfErrorCode_Success) {
        return (jlong)file_size;
    } else {
        LOGE("Failed to get file size, error: %d", error_code);
        return -1;
    }
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeExtractPage(JNIEnv *env, jobject /* this */,
                                                      jstring inputPath, jint pageNumber, jstring outputPath) {
    LOGI("nativeExtractPage called");
    
    if (!pdf_extract_page_ptr) {
        LOGE("pdf_extract_page_ptr is null - function not available");
        return JNI_FALSE;
    }
    
    const char* inputPathStr = env->GetStringUTFChars(inputPath, nullptr);
    const char* outputPathStr = env->GetStringUTFChars(outputPath, nullptr);
    
    LOGI("Extracting page %d from %s to %s", pageNumber, inputPathStr, outputPathStr);
    
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_extract_page_ptr(inputPathStr, pageNumber, outputPathStr, &error_code, &error_message);
    
    LOGI("pdf_extract_page returned: %s, error_code: %d", 
         result ? "true" : "false", 
         error_code);
    
    if (error_message) {
        LOGI("Error message: %s", error_message);
        free_c_string_ptr(error_message);
    }
    
    env->ReleaseStringUTFChars(inputPath, inputPathStr);
    env->ReleaseStringUTFChars(outputPath, outputPathStr);
    
    return (result && error_code == PdfErrorCode_Success) ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeSplitAtPage(JNIEnv *env, jobject /* this */,
                                                      jstring inputPath, jint splitPage, jstring outputPrefix) {
    LOGI("nativeSplitAtPage called");
    
    if (!pdf_split_at_page_ptr) {
        LOGE("pdf_split_at_page_ptr is null - function not available");
        return JNI_FALSE;
    }
    
    const char* inputPathStr = env->GetStringUTFChars(inputPath, nullptr);
    const char* outputPrefixStr = env->GetStringUTFChars(outputPrefix, nullptr);
    
    LOGI("Splitting %s at page %d with prefix %s", inputPathStr, splitPage, outputPrefixStr);
    
    PdfErrorCode error_code = PdfErrorCode_Success;
    char* error_message = nullptr;
    
    bool result = pdf_split_at_page_ptr(inputPathStr, splitPage, outputPrefixStr, &error_code, &error_message);
    
    LOGI("pdf_split_at_page returned: %s, error_code: %d", 
         result ? "true" : "false", 
         error_code);
    
    if (error_message) {
        LOGI("Error message: %s", error_message);
        free_c_string_ptr(error_message);
    }
    
    env->ReleaseStringUTFChars(inputPath, inputPathStr);
    env->ReleaseStringUTFChars(outputPrefix, outputPrefixStr);
    
    return (result && error_code == PdfErrorCode_Success) ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_smart_1pdf_SpdfcorePlugin_nativeGetVersion(JNIEnv *env, jobject /* this */) {
    LOGI("nativeGetVersion called");
    
    if (!init_spdfcore_ffi()) {
        LOGE("Failed to initialize spdfcore_ffi library");
        return env->NewStringUTF("unknown");
    }
    
    if (!spdfcore_version_ptr) {
        LOGI("spdfcore_version function not available, returning fallback version");
        return env->NewStringUTF("1.0.0");
    }
    
    const char* version = spdfcore_version_ptr();
    if (version) {
        LOGI("Native version: %s", version);
        return env->NewStringUTF(version);
    } else {
        LOGE("spdfcore_version returned null");
        return env->NewStringUTF("unknown");
    }
}