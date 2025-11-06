/* spdfcore C Header
 * Auto-generated with cbindgen
 * 
 * PDF processing library with split, merge, and manipulation capabilities
 */

#ifndef SPDFCORE_H
#define SPDFCORE_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifndef SPDFCORE_H
#define SPDFCORE_H

/* Generated with cbindgen:0.29.0 */

#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * C-compatible error codes for FFI
 */
typedef enum PdfErrorCode {
    PdfErrorCode_Success = 0,
    PdfErrorCode_FileNotFound = 1,
    PdfErrorCode_InvalidPdf = 2,
    PdfErrorCode_EncryptedPdf = 3,
    PdfErrorCode_PermissionDenied = 4,
    PdfErrorCode_OutOfMemory = 5,
    PdfErrorCode_InvalidParameter = 6,
    PdfErrorCode_UnsupportedFeature = 7,
    PdfErrorCode_IoError = 8,
    PdfErrorCode_ParseError = 9,
    PdfErrorCode_EncryptionError = 10,
    PdfErrorCode_UnknownError = 99,
} PdfErrorCode;

/**
 * PDF metadata structure for C compatibility
 */
typedef struct PdfMetadata {
    char *title;
    char *author;
    char *subject;
    char *keywords;
    char *creator;
    char *producer;
    int64_t creation_date;
    int64_t modification_date;
    int32_t page_count;
    uint64_t file_size;
} PdfMetadata;

/**
 * Initialize the spdfcore library
 * Returns: true if success, false if failed
 */
bool spdfcore_init(void);

/**
 * Clean up library resources
 */
void spdfcore_cleanup(void);

/**
 * Get library version
 * Returns: version string (null-terminated)
 */
const char *spdfcore_version(void);

/**
 * Get PDF page count
 * Params: file_path, page_count (output), error_code (output), error_message (output)
 * Returns: true if success
 */
bool pdf_get_page_count(const char *file_path,
                        int32_t *page_count,
                        enum PdfErrorCode *error_code,
                        char **error_message);

/**
 * Get PDF file size
 * Params: file_path, file_size (output), error_code (output), error_message (output)
 * Returns: true if success
 */
bool pdf_get_file_size(const char *file_path,
                       uint64_t *file_size,
                       enum PdfErrorCode *error_code,
                       char **error_message);

/**
 * Validate PDF file
 * Params: file_path, is_valid (output), error_code (output), error_message (output)
 * Returns: true if function succeeded (check is_valid for actual result)
 */
bool pdf_validate(const char *file_path,
                  bool *is_valid,
                  enum PdfErrorCode *error_code,
                  char **error_message);

/**
 * Merge multiple PDF files
 * Params: input_paths (array), path_count, output_path, error_code (output), error_message (output)
 * Returns: true if success
 */
bool pdf_merge_files(const char *const *input_paths,
                     size_t path_count,
                     const char *output_path,
                     enum PdfErrorCode *error_code,
                     char **error_message);

/**
 * Split PDF by extracting specific pages
 * Params: input_path, pages (array), page_count, output_path, error_code (output), error_message (output)
 * Returns: true if success
 */
bool pdf_split_by_pages(const char *input_path,
                        const int32_t *pages,
                        size_t page_count,
                        const char *output_path,
                        enum PdfErrorCode *error_code,
                        char **error_message);

/**
 * Extract single page from PDF
 * Params: input_path, page_number, output_path, error_code (output), error_message (output)
 * Returns: true if success
 */
bool pdf_extract_page(const char *input_path,
                      int32_t page_number,
                      const char *output_path,
                      enum PdfErrorCode *error_code,
                      char **error_message);

/**
 * Split PDF at a specific page (creates two documents)
 * Params: input_path, split_page, output_prefix, error_code (output), error_message (output)
 * Returns: true if success
 * Example: If PDF has 10 pages and split_page=5, creates:
 *   - output_prefix_part1.pdf (pages 1-5)
 *   - output_prefix_part2.pdf (pages 6-10)
 */
bool pdf_split_at_page(const char *input_path,
                       int32_t split_page,
                       const char *output_prefix,
                       enum PdfErrorCode *error_code,
                       char **error_message);

/**
 * Free C string allocated by library
 * Params: str (can be null)
 */
void free_c_string(char *str);

/**
 * Free PDF metadata and its allocated strings
 */
void free_pdf_metadata(struct PdfMetadata *metadata);

#endif  /* SPDFCORE_H */

#endif /* SPDFCORE_H */
