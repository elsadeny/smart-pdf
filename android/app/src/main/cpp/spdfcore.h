#ifndef SPDFCORE_H
#define SPDFCORE_H

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

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

bool spdfcore_init(void);
void spdfcore_cleanup(void);
const char *spdfcore_version(void);

bool pdf_get_page_count(const char *file_path, int32_t *page_count, PdfErrorCode *error_code, char **error_message);
bool pdf_get_file_size(const char *file_path, uint64_t *file_size, PdfErrorCode *error_code, char **error_message);
bool pdf_validate(const char *file_path, bool *is_valid, PdfErrorCode *error_code, char **error_message);
bool pdf_merge_files(const char *const *input_paths, size_t path_count, const char *output_path, PdfErrorCode *error_code, char **error_message);
bool pdf_split_by_pages(const char *input_path, const int32_t *pages, size_t page_count, const char *output_path, PdfErrorCode *error_code, char **error_message);
bool pdf_extract_page(const char *input_path, int32_t page_number, const char *output_path, PdfErrorCode *error_code, char **error_message);
bool pdf_split_at_page(const char *input_path, int32_t split_page, const char *output_prefix, PdfErrorCode *error_code, char **error_message);

void free_c_string(char *str);
void free_pdf_metadata(PdfMetadata *metadata);

#ifdef __cplusplus
}
#endif

#endif // SPDFCORE_H
