#
# Be sure to run `pod lib lint CBRCloudKitConnection.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CBRCloudKitConnection"
  s.version          = "0.10.3"
  s.summary          = "CloudBridgeConnection for CloudKit."
  s.homepage         = "https://github.com/Cloud-Bridge/CBRCloudKitConnection"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/Cloud-Bridge/CBRCloudKitConnection.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'CBRCloudKitConnection'
  s.frameworks = 'CloudKit'
  s.dependency 'CloudBridge', '~> 0.10.0'
  s.prefix_header_contents = '#ifndef NS_BLOCK_ASSERTIONS', '#define __assert_unused', '#else', '#define __assert_unused __unused', '#endif'
end
