cmake_minimum_required(VERSION 3.10)
project(flutter_launch_arguments_ffi VERSION 1.0.0 LANGUAGES C)

# CRITICAL: Reference iOS header location (single source of truth)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../ios/Sources/flutter_launch_arguments_ffi/include)

add_library(flutter_launch_arguments_ffi SHARED
    src/main/cpp/android_args.c
)

find_library(log-lib log)
target_link_libraries(flutter_launch_arguments_ffi ${log-lib})

target_link_options(flutter_launch_arguments_ffi PRIVATE "-Wl,-z,max-page-size=16384")
