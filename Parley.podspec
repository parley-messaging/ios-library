Pod::Spec.new do |s|
  s.name             = 'Parley'
  s.version          = '3.8.0'
  s.summary          = 'Easily create a secure chat within three steps with the Parley Messaging iOS library.'
  s.homepage         = 'https://github.com/parley-messaging/ios-library'
  s.author           = { 'Webuildapps' => 'hello@webuildapps.com' }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.source           = { :git => 'git@github.com:parley-messaging/ios-library.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '12.0'

  s.source_files = 'Sources/Parley/**/*.swift'
  s.resources = [
    "Sources/Parley/**/*.lproj",
    "Sources/Parley/**/*.xcassets",
    "Sources/Parley/**/*.xib"
  ]

  s.dependency 'Alamofire', '~> 5.8.1'
  s.dependency 'AlamofireImage', '~> 4.3.0'

  s.dependency 'ReachabilitySwift', '~> 5.0.0'

  s.dependency 'MarkdownKit', '~> 1.6'

  s.frameworks = 'Photos', 'Security'
end
