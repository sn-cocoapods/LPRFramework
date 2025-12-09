Pod::Spec.new do |s|
  s.name             = 'LPRFramework'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LPRFramework.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/snice/LPRFramework'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'snice' => 'zhuzheteng@gmail.com' }
  s.source           = { :git => 'https://github.com/snice/LPRFramework.git', :tag => s.version.to_s }

  s.platform = :ios
  s.ios.deployment_target = '12.0'
  s.requires_arc = true
  s.static_framework = true
  
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-all_load -lc++',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }

  s.source_files = 'Sources/Classes/**/*'
  s.resources = 'Sources/Assets/*'
  s.frameworks = 'CoreML'
  s.libraries = 'c++'
  s.vendored_frameworks = 'Frameworks/*.{framework,xcframework}'
  
end
