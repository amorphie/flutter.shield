#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_shield.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_shield'
  s.version          = '0.0.1'
  s.summary          = 'Shield App'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/amorphie/flutter.shield'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Burgan Bank' => 'info@burgan.com.tr' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
