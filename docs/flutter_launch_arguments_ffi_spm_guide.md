# Flutter Launch Arguments FFI - Production Implementation Guide
## Android & iOS with Swift Package Manager

## Project Overview
Rebuild flutter_launch_arguments using dart:ffi and ffigen for **Android and iOS**, using **Swift Package Manager** (SPM) instead of deprecated CocoaPods. This provides performance improvements through direct native calls while maintaining the original API.

**Architecture:** Call native once, parse in Dart, cache results in singleton.

---

## Quick Start

```bash
flutter create --template=plugin_ffi --platforms=android,ios flutter_launch_arguments_ffi
cd flutter_launch_arguments_ffi
```

---

## Project Structure (SPM-Optimized)

```
flutter_launch_arguments_ffi/
├── lib/
│   ├── flutter_launch_arguments_ffi.dart
│   └── src/
│       └── flutter_launch_arguments_bindings_generated.dart
│
├── ios/
│   ├── Sources/
│   │   └── flutter_launch_arguments_ffi/
│   │       ├── include/
│   │       │   └── launch_arguments.h          # Shared header (iOS primary)
│   │       ├── ios_args.m                      # iOS implementation
│   │       └── FlutterLaunchArgumentsFfiPlugin.swift
│   └── Package.swift                            # SPM manifest
│
├── android/
│   ├── src/
│   │   └── main/
│   │       ├── java/com/example/flutter_launch_arguments_ffi/
│   │       │   └── FlutterLaunchArgumentsFfiPlugin.java
│   │       └── cpp/
│   │           └── android_args.c              # Android implementation
│   ├── CMakeLists.txt                          # References iOS header
│   └── build.gradle
│
├── example/
│   └── lib/main.dart
├── ffigen.yaml
└── pubspec.yaml
```

**Key Design Decision:** Header lives in `ios/Sources/.../include/` because SPM cannot reference parent directories. Android CMake references this location.

---

## Step 1: C Header (Shared Interface)

**File:** `ios/Sources/flutter_launch_arguments_ffi/include/launch_arguments.h`

```c
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
```

---

## Step 2: iOS Implementation with SPM

### Part A: Native Code

**File:** `ios/Sources/flutter_launch_arguments_ffi/ios_args.m`

```objective-c
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
```

### Part B: Swift Package Manager Manifest

**File:** `ios/Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_launch_arguments_ffi",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "flutter_launch_arguments_ffi",
            targets: ["flutter_launch_arguments_ffi"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_launch_arguments_ffi",
            dependencies: [],
            path: "Sources/flutter_launch_arguments_ffi",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
            ]
        )
    ],
    cLanguageStandard: .c11
)
```

### Part C: Plugin Registration (Optional but Recommended)

**File:** `ios/Sources/flutter_launch_arguments_ffi/FlutterLaunchArgumentsFfiPlugin.swift`

```swift
import Flutter
import UIKit

public class FlutterLaunchArgumentsFfiPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // FFI plugin - no platform channel needed
        // This registration ensures proper plugin lifecycle
    }
}
```

---

## Step 3: Android Implementation with JNI

### Part A: Java Plugin (ActivityAware)

**File:** `android/src/main/java/com/example/flutter_launch_arguments_ffi/FlutterLaunchArgumentsFfiPlugin.java`

```java
package com.example.flutter_launch_arguments_ffi;

import android.app.Activity;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

public class FlutterLaunchArgumentsFfiPlugin implements FlutterPlugin, ActivityAware {
    
    private native void nativeSetActivity(Activity activity);
    
    static {
        System.loadLibrary("flutter_launch_arguments_ffi");
    }
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    }
    
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    }
    
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        nativeSetActivity(binding.getActivity());
    }
    
    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }
    
    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        nativeSetActivity(binding.getActivity());
    }
    
    @Override
    public void onDetachedFromActivity() {
        nativeSetActivity(null);
    }
}
```

### Part B: Native JNI Implementation

**File:** `android/src/main/cpp/android_args.c`

```c
#include <jni.h>
#include <android/log.h>
#include <stdlib.h>
#include <string.h>
#include "launch_arguments.h"

#define LOG_TAG "LaunchArgs"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static JavaVM* g_jvm = NULL;
static jobject g_activity = NULL;

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("JNI_OnLoad called");
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

static JNIEnv* get_jni_env() {
    if (g_jvm == NULL) return NULL;
    
    JNIEnv* env = NULL;
    int status = (*g_jvm)->GetEnv(g_jvm, (void**)&env, JNI_VERSION_1_6);
    
    if (status == JNI_EDETACHED) {
        if ((*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL) != JNI_OK) {
            return NULL;
        }
    }
    
    return env;
}

JNIEXPORT void JNICALL
Java_com_example_flutter_1launch_1arguments_1ffi_FlutterLaunchArgumentsFfiPlugin_nativeSetActivity(
    JNIEnv* env, jobject obj, jobject activity) {
    
    if (g_activity != NULL) {
        (*env)->DeleteGlobalRef(env, g_activity);
        g_activity = NULL;
    }
    
    if (activity != NULL) {
        g_activity = (*env)->NewGlobalRef(env, activity);
        LOGI("Activity stored");
    }
}

FFI_PLUGIN_EXPORT CommandLineArguments* get_command_line_arguments(void) {
    CommandLineArguments* result = calloc(1, sizeof(CommandLineArguments));
    
    JNIEnv* env = get_jni_env();
    if (env == NULL || g_activity == NULL) {
        result->error_code = -1;
        result->error_message = strdup("Activity not available");
        return result;
    }
    
    jclass activityClass = (*env)->GetObjectClass(env, g_activity);
    jmethodID getIntentMethod = (*env)->GetMethodID(env, activityClass, 
        "getIntent", "()Landroid/content/Intent;");
    jobject intent = (*env)->CallObjectMethod(env, g_activity, getIntentMethod);
    
    if (intent == NULL) {
        (*env)->DeleteLocalRef(env, activityClass);
        result->count = 0;
        return result;
    }
    
    jclass intentClass = (*env)->GetObjectClass(env, intent);
    jmethodID getExtrasMethod = (*env)->GetMethodID(env, intentClass,
        "getExtras", "()Landroid/os/Bundle;");
    jobject bundle = (*env)->CallObjectMethod(env, intent, getExtrasMethod);
    
    if (bundle == NULL) {
        (*env)->DeleteLocalRef(env, intentClass);
        (*env)->DeleteLocalRef(env, intent);
        (*env)->DeleteLocalRef(env, activityClass);
        result->count = 0;
        return result;
    }
    
    jclass bundleClass = (*env)->GetObjectClass(env, bundle);
    jmethodID keySetMethod = (*env)->GetMethodID(env, bundleClass,
        "keySet", "()Ljava/util/Set;");
    jobject keySet = (*env)->CallObjectMethod(env, bundle, keySetMethod);
    
    jclass setClass = (*env)->GetObjectClass(env, keySet);
    jmethodID toArrayMethod = (*env)->GetMethodID(env, setClass,
        "toArray", "()[Ljava/lang/Object;");
    jobjectArray keysArray = (*env)->CallObjectMethod(env, keySet, toArrayMethod);
    
    jsize keyCount = (*env)->GetArrayLength(env, keysArray);
    result->count = keyCount;
    result->arguments = malloc(sizeof(char*) * keyCount);
    
    jmethodID getMethod = (*env)->GetMethodID(env, bundleClass,
        "get", "(Ljava/lang/String;)Ljava/lang/Object;");
    
    for (jsize i = 0; i < keyCount; i++) {
        jstring keyString = (*env)->GetObjectArrayElement(env, keysArray, i);
        const char* keyChars = (*env)->GetStringUTFChars(env, keyString, NULL);
        
        jobject valueObj = (*env)->CallObjectMethod(env, bundle, getMethod, keyString);
        
        char argBuffer[1024];
        if (valueObj != NULL) {
            jclass objClass = (*env)->GetObjectClass(env, valueObj);
            jmethodID toStringMethod = (*env)->GetMethodID(env, objClass,
                "toString", "()Ljava/lang/String;");
            jstring valueString = (*env)->CallObjectMethod(env, valueObj, toStringMethod);
            const char* valueChars = (*env)->GetStringUTFChars(env, valueString, NULL);
            
            snprintf(argBuffer, sizeof(argBuffer), "--%s=%s", keyChars, valueChars);
            
            (*env)->ReleaseStringUTFChars(env, valueString, valueChars);
            (*env)->DeleteLocalRef(env, valueString);
            (*env)->DeleteLocalRef(env, objClass);
        } else {
            snprintf(argBuffer, sizeof(argBuffer), "--%s", keyChars);
        }
        
        result->arguments[i] = strdup(argBuffer);
        
        (*env)->ReleaseStringUTFChars(env, keyString, keyChars);
        (*env)->DeleteLocalRef(env, keyString);
        if (valueObj) (*env)->DeleteLocalRef(env, valueObj);
    }
    
    (*env)->DeleteLocalRef(env, keysArray);
    (*env)->DeleteLocalRef(env, setClass);
    (*env)->DeleteLocalRef(env, keySet);
    (*env)->DeleteLocalRef(env, bundleClass);
    (*env)->DeleteLocalRef(env, bundle);
    (*env)->DeleteLocalRef(env, intentClass);
    (*env)->DeleteLocalRef(env, intent);
    (*env)->DeleteLocalRef(env, activityClass);
    
    return result;
}

FFI_PLUGIN_EXPORT void free_command_line_arguments(CommandLineArguments* args) {
    if (args == NULL) return;
    
    if (args->arguments != NULL) {
        for (int i = 0; i < args->count; i++) {
            free(args->arguments[i]);
        }
        free(args->arguments);
    }
    
    free(args->error_message);
    free(args);
}
```

### Part C: Android CMakeLists.txt (References iOS Header)

**File:** `android/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.10)
project(flutter_launch_arguments_ffi VERSION 1.0.0 LANGUAGES C)

# Find JNI
find_package(JNI REQUIRED)
include_directories(${JNI_INCLUDE_DIRS})

# CRITICAL: Reference iOS header location
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../ios/Sources/flutter_launch_arguments_ffi/include)

add_library(flutter_launch_arguments_ffi SHARED
    src/main/cpp/android_args.c
)

find_library(log-lib log)
target_link_libraries(flutter_launch_arguments_ffi ${log-lib})

target_link_options(flutter_launch_arguments_ffi PRIVATE "-Wl,-z,max-page-size=16384")
```

### Part D: Android Gradle

**File:** `android/build.gradle`

```gradle
android {
    compileSdkVersion 34
    ndkVersion "27.0.12077973"
    
    defaultConfig {
        minSdkVersion 21
        
        externalNativeBuild {
            cmake {
                cppFlags "-std=c11"
            }
        }
        
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
        }
    }
    
    externalNativeBuild {
        cmake {
            path "CMakeLists.txt"
        }
    }
}
```

---

## Step 4: FFI Bindings Configuration

**File:** `ffigen.yaml`

```yaml
name: FlutterLaunchArgumentsBindings
description: 'FFI bindings for launch arguments'
output: 'lib/src/flutter_launch_arguments_bindings_generated.dart'
language: c

headers:
  entry-points:
    - 'ios/Sources/flutter_launch_arguments_ffi/include/launch_arguments.h'

preamble: |
  // ignore_for_file: camel_case_types, non_constant_identifier_names

functions:
  include:
    - 'get_command_line_arguments'
    - 'free_command_line_arguments'
  symbol-address:
    include:
      - 'get_command_line_arguments'
      - 'free_command_line_arguments'

structs:
  include:
    - 'CommandLineArguments'
```

**Generate bindings:**
```bash
dart run ffigen --config ffigen.yaml
```

---

## Step 5: Dart API Layer

**File:** `lib/flutter_launch_arguments_ffi.dart`

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'src/flutter_launch_arguments_bindings_generated.dart';

const String _libName = 'flutter_launch_arguments_ffi';

final DynamicLibrary _dylib = () {
  if (Platform.isIOS) {
    return DynamicLibrary.process();  // SPM bundles as framework
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
}();

final FlutterLaunchArgumentsBindings _bindings = 
    FlutterLaunchArgumentsBindings(_dylib);

class FlutterLaunchArguments {
  static FlutterLaunchArguments? _instance;
  
  final Map<String, String> _keyValueArgs = {};
  final List<String> _allArguments = [];
  bool _initialized = false;
  
  FlutterLaunchArguments._internal() {
    _initialize();
  }
  
  static FlutterLaunchArguments get instance {
    _instance ??= FlutterLaunchArguments._internal();
    return _instance!;
  }
  
  void _initialize() {
    if (_initialized) return;
    
    final Pointer<CommandLineArguments> resultPtr = 
        _bindings.get_command_line_arguments();
    
    if (resultPtr == nullptr) {
      throw FlutterLaunchArgumentsException('Native returned null');
    }
    
    try {
      final result = resultPtr.ref;
      
      if (result.error_code != 0) {
        final error = result.error_message != nullptr
            ? result.error_message.cast<Utf8>().toDartString()
            : 'Error code: ${result.error_code}';
        throw FlutterLaunchArgumentsException(error);
      }
      
      if (result.count > 0 && result.arguments != nullptr) {
        final argsArray = result.arguments.cast<Pointer<Utf8>>();
        
        for (int i = 0; i < result.count; i++) {
          final argPtr = argsArray[i];
          if (argPtr == nullptr) continue;
          
          final arg = argPtr.toDartString();
          _allArguments.add(arg);
          _parseArgument(arg);
        }
      }
      
      _initialized = true;
    } finally {
      _bindings.free_command_line_arguments(resultPtr);
    }
  }
  
  void _parseArgument(String arg) {
    if (arg.startsWith('--') && arg.contains('=')) {
      final stripped = arg.substring(2);
      final idx = stripped.indexOf('=');
      _keyValueArgs[stripped.substring(0, idx)] = stripped.substring(idx + 1);
      return;
    }
    
    if (arg.startsWith('--')) {
      _keyValueArgs[arg.substring(2)] = 'true';
      return;
    }
    
    if (arg.startsWith('-') && !arg.startsWith('--')) {
      _keyValueArgs[arg.substring(1)] = 'true';
    }
  }
  
  static String? getString(String key) => instance._keyValueArgs[key];
  
  static bool getBool(String flag) {
    final value = instance._keyValueArgs[flag];
    return value != null && (value.toLowerCase() == 'true' || value == '1');
  }
  
  static List<String> getAll() => List.unmodifiable(instance._allArguments);
  
  static void clearCache() {
    _instance?._keyValueArgs.clear();
    _instance?._allArguments.clear();
    _instance?._initialized = false;
    _instance = null;
  }
}

class FlutterLaunchArgumentsException implements Exception {
  final String message;
  FlutterLaunchArgumentsException(this.message);
  
  @override
  String toString() => 'FlutterLaunchArgumentsException: $message';
}
```

---

## Step 6: pubspec.yaml

```yaml
name: flutter_launch_arguments_ffi
description: FFI-based launch arguments with SPM support
version: 0.0.1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.0

dev_dependencies:
  ffigen: ^13.0.0
  flutter_test:
    sdk: flutter

flutter:
  plugin:
    platforms:
      android:
        package: com.example.flutter_launch_arguments_ffi
        pluginClass: FlutterLaunchArgumentsFfiPlugin
        ffiPlugin: true
      ios:
        pluginClass: FlutterLaunchArgumentsFfiPlugin
        ffiPlugin: true
```

---

## Step 7: Example App

**File:** `example/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_launch_arguments_ffi/flutter_launch_arguments_ffi.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> _args = [];
  String? _foo;
  bool _enabled = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    try {
      _args = FlutterLaunchArguments.getAll();
      _foo = FlutterLaunchArguments.getString('foo');
      _enabled = FlutterLaunchArguments.getBool('enabled');
    } catch (e) {
      _error = e.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Launch Arguments FFI')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error.isNotEmpty)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error),
                ),
              ),
            Card(child: ListTile(title: Text('Count: ${_args.length}'))),
            Card(child: ListTile(title: const Text('foo'), subtitle: Text(_foo ?? 'null'))),
            Card(child: ListTile(title: const Text('enabled'), subtitle: Text('$_enabled'))),
            const Divider(),
            ..._args.map((arg) => Card(child: ListTile(title: Text(arg)))),
          ],
        ),
      ),
    );
  }
}
```

---

## Testing Commands

### Android
```bash
cd example
flutter build apk
flutter install

adb shell am start \
  -n com.example.flutter_launch_arguments_ffi_example/.MainActivity \
  -e foo "hello" \
  -ez enabled true
```

### iOS
```bash
cd example
flutter run -d <ios-device>

# Or via Xcode scheme:
# Product → Scheme → Edit Scheme → Arguments
# Add: --foo=bar --enabled
```

---

## Migration Steps from Template

After creating with `flutter create --template=plugin_ffi`:

1. **Move header to SPM location:**
```bash
mkdir -p ios/Sources/flutter_launch_arguments_ffi/include
mv src/launch_arguments.h ios/Sources/flutter_launch_arguments_ffi/include/
```

2. **Create iOS implementation:**
```bash
touch ios/Sources/flutter_launch_arguments_ffi/ios_args.m
# Add implementation from Step 2
```

3. **Create Package.swift:**
```bash
touch ios/Package.swift
# Add SPM manifest from Step 2
```

4. **Move Android implementation:**
```bash
mkdir -p android/src/main/cpp
mv src/android_args.c android/src/main/cpp/
```

5. **Update CMakeLists.txt to reference iOS header**

6. **Update ffigen.yaml path**

7. **Generate bindings:**
```bash
dart run ffigen --config ffigen.yaml
```

---

## Why This Structure?

1. **SPM Compliance:** Package.swift can only reference files within ios/ directory
2. **Future-Proof:** CocoaPods deprecation means SPM is mandatory
3. **Android Flexibility:** CMake can reference any path, so it points to iOS header
4. **Single Source of Truth:** Header in one location, both platforms use it
5. **Modern Plugin Pattern:** Matches Flutter's evolving best practices

This is the production-ready, 2025-forward architecture for Flutter FFI plugins.
