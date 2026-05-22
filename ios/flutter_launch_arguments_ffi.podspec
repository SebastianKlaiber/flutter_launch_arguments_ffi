#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_launch_arguments_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_launch_arguments_ffi'
  s.version          = '0.2.0'
  s.summary          = 'FFI-based launch arguments with SPM support'
  s.description      = <<-DESC
FFI-based launch arguments plugin with Swift Package Manager support for iOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flutter_launch_arguments_ffi/Sources/**/*.{swift,m,h}'
  s.public_header_files = 'flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/include'
  }
  s.swift_version = '5.0'
end
