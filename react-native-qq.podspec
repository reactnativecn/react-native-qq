#
#  Be sure to run `pod spec lint react-native-qq.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

require "json"

package = JSON.parse(File.read('package.json'))

Pod::Spec.new do |s|
  
  s.name         = "react-native-qq"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.author       = 'tdzl2003'
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/EternalChildren/react-native-qq.git"}
  s.source_files  = "ios/**/*.{h,m}"
  s.vendored_frameworks = 'ios/RCTQQAPI/TencentOpenAPI.framework'
  s.libraries = 'iconv', 'sqlite3', 'c++', 'z'
  s.dependency "React"

end