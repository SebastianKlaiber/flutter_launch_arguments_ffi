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
    if (g_jvm == NULL) {
        LOGE("JavaVM not initialized");
        return NULL;
    }

    JNIEnv* env = NULL;
    int status = (*g_jvm)->GetEnv(g_jvm, (void**)&env, JNI_VERSION_1_6);

    if (status == JNI_EDETACHED) {
        if ((*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL) != JNI_OK) {
            LOGE("Failed to attach current thread");
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
        LOGI("Activity reference cleared");
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
        LOGE("Activity not available (env=%p, activity=%p)", env, g_activity);
        result->error_code = -1;
        result->error_message = strdup("Activity not available");
        result->count = 0;
        return result;
    }

    LOGI("Retrieving launch arguments from Intent extras");

    jclass activityClass = (*env)->GetObjectClass(env, g_activity);
    jmethodID getIntentMethod = (*env)->GetMethodID(env, activityClass,
        "getIntent", "()Landroid/content/Intent;");
    jobject intent = (*env)->CallObjectMethod(env, g_activity, getIntentMethod);

    if (intent == NULL) {
        LOGI("No intent found");
        (*env)->DeleteLocalRef(env, activityClass);
        result->count = 0;
        result->error_code = 0;
        return result;
    }

    jclass intentClass = (*env)->GetObjectClass(env, intent);
    jmethodID getExtrasMethod = (*env)->GetMethodID(env, intentClass,
        "getExtras", "()Landroid/os/Bundle;");
    jobject bundle = (*env)->CallObjectMethod(env, intent, getExtrasMethod);

    if (bundle == NULL) {
        LOGI("No extras in intent");
        (*env)->DeleteLocalRef(env, intentClass);
        (*env)->DeleteLocalRef(env, intent);
        (*env)->DeleteLocalRef(env, activityClass);
        result->count = 0;
        result->error_code = 0;
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
    LOGI("Found %d launch arguments", keyCount);

    result->count = keyCount;
    result->error_code = 0;
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
            LOGI("Arg %d: --%s=%s", i, keyChars, valueChars);

            (*env)->ReleaseStringUTFChars(env, valueString, valueChars);
            (*env)->DeleteLocalRef(env, valueString);
            (*env)->DeleteLocalRef(env, objClass);
        } else {
            snprintf(argBuffer, sizeof(argBuffer), "--%s", keyChars);
            LOGI("Arg %d: --%s", i, keyChars);
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
