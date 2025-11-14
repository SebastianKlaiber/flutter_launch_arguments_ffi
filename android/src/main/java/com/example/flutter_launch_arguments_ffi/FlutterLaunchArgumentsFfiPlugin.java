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
        // FFI plugin - no platform channel needed
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // Cleanup if needed
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        nativeSetActivity(binding.getActivity());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // Activity temporarily detached
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
