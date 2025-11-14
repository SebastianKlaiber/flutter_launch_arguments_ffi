#ifndef LAUNCH_ARGUMENTS_H
#define LAUNCH_ARGUMENTS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
  #define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
  #define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

typedef struct {
    char **arguments;
    int32_t count;
    int32_t error_code;
    char *error_message;
} CommandLineArguments;

FFI_PLUGIN_EXPORT CommandLineArguments* get_command_line_arguments(void);
FFI_PLUGIN_EXPORT void free_command_line_arguments(CommandLineArguments *args);

#ifdef __cplusplus
}
#endif

#endif
