Pod::Spec.new do |s|
  s.name             =	'CMPComapiChat'
  s.version          =	'1.0.0'
  s.license          = 	'MIT'
  s.summary          =	'Chat SDK for Comapi. Extends Foundation with additional logic for Chat apps.'
  s.description      = <<-DESC
# iOS SDK for Comapi
Extension to ComapiFoundation allowing the integrator for easier implementation of Chat logic and management. Written in Objective-C.
For more information about the integration please visit [the website](http://docs.comapi.com/reference#one-sdk-ios).
						DESC
  s.homepage         = 'https://github.com/comapi/CMPComapiChat'
  s.author           = { 'Comapi' => 'technicalmanagement@comapi.com' }
  s.source           = { :git => 'https://github.com/comapi/comapi-chat-sdk-ios-objc.git', :branch => 'dev' }
  s.social_media_url = 'https://twitter.com/comapimessaging'

  s.ios.deployment_target = '10.0'
  s.requires_arc          = true
  s.source_files          = 'Sources/**/*.{h,m}'
  s.resources             = 'Sources/Core/Resources/*'

  s.dependency 'CMPComapiFoundation'
  
end
