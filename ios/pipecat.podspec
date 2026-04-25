#
# See http://guides.cocoapods.org/syntax/podspec.html for podspec syntax.
# Run `pod lib lint pipecat.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pipecat'
  s.version          = '0.2.0'
  s.summary          = 'Flutter plugin for Pipecat real-time AI voice and multimodal agents.'
  s.description      = <<-DESC
Dart bindings for the native Pipecat iOS client SDK. Provides a type-safe
Flutter API over the Pipecat real-time AI voice and multimodal platform.
                       DESC
  s.homepage         = 'https://github.com/minhtri1401/pipecat_flutter'
  s.license          = { :type => 'BSD-2-Clause', :file => '../LICENSE' }
  s.author           = { 'MinhTri1401' => 'tri.dev.dhm@gmail.com' }
  s.source           = { :git => 'https://github.com/minhtri1401/pipecat_flutter.git', :tag => s.version.to_s }
  s.source_files     = 'pipecat/Sources/pipecat/**/*'
  s.dependency 'Flutter'
  s.dependency 'PipecatClientIOS', '~> 1.2.0'
  s.dependency 'PipecatClientIOSDaily', '~> 1.2.0'
  s.dependency 'PipecatClientIOSSmallWebrtc', '~> 1.2.0'
  s.platform         = :ios, '13.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'

  s.resource_bundles = {
    'pipecat_privacy' => ['pipecat/Sources/pipecat/PrivacyInfo.xcprivacy'],
  }
end
