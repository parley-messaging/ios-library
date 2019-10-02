Pod::Spec.new do |s|
  s.name             = 'Parley'
  s.version          = '3.0.0'
  s.summary          = 'Easily create a secure chat within three steps with the Parley Messaging iOS library.'
  s.homepage         = 'https://github.com/parley-messaging/ios-library'
  s.author           = { 'Webuildapps' => 'hello@webuildapps.com' }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.source           = { :git => 'https://github.com/parley-messaging/ios-library.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'
  
  s.ios.deployment_target = '11.0'

  s.source_files = 'Source/**/*.swift'
  s.resources = [
    "Source/**/*.lproj",
    "Source/**/*.xcassets",
    "Source/**/*.xib",
  ]

  s.dependency 'Alamofire', '~> 4.8.0'
  s.dependency 'AlamofireImage', '~> 3.5.2'
  s.dependency 'AlamofireObjectMapper', '~> 5.2.0'

  s.dependency 'TrustKit', '~> 1.6.1'

  s.dependency 'SwiftGifOrigin', '~> 1.7.0'

  s.dependency 'ReachabilitySwift', '~> 4.3.1'

  s.dependency 'MarkdownKit', '~> 1.5'

  s.frameworks = 'Photos', 'Security'
end
