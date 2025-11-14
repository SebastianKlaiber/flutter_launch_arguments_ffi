#import <Foundation/Foundation.h>
#include "include/launch_arguments.h"

FFI_PLUGIN_EXPORT CommandLineArguments* get_command_line_arguments(void) {
    @autoreleasepool {
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        NSArray *arguments = [processInfo arguments];

        CommandLineArguments *result = malloc(sizeof(CommandLineArguments));
        result->count = (int32_t)[arguments count];
        result->error_code = 0;
        result->error_message = NULL;
        result->arguments = malloc(sizeof(char*) * result->count);

        for (int i = 0; i < result->count; i++) {
            NSString *arg = arguments[i];
            const char *utf8 = [arg UTF8String];
            result->arguments[i] = strdup(utf8);
        }

        return result;
    }
}

FFI_PLUGIN_EXPORT void free_command_line_arguments(CommandLineArguments *args) {
    if (args == NULL) return;

    for (int i = 0; i < args->count; i++) {
        free(args->arguments[i]);
    }
    free(args->arguments);
    free(args->error_message);
    free(args);
}
