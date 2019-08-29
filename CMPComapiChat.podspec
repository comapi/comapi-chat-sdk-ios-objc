Pod::Spec.new do |s|
  s.version = '1.0.1'
  s.name             =	'CMPComapiChat'
  s.license          = 	'MIT'
  s.summary          =	'Chat SDK for Comapi. Extends Foundation with additional logic for Chat apps.'
  s.description      = <<-DESC
# iOS SDK for Comapi
Extension to ComapiFoundation allowing the integrator for easier implementation of Chat logic and management. Written in Objective-C.
For more information about the integration please visit [the website](http://docs.comapi.com/reference#one-sdk-ios).
						DESC
  s.homepage         = 'https://github.com/comapi/comapi-chat-sdk-ios-objc'
  s.author           = { 'Comapi' => 'technicalmanagement@comapi.com' }
  s.source           = { :git => 'https://github.com/comapi/comapi-chat-sdk-ios-objc.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.requires_arc          = true
  s.source_files          = 'Sources/**/*.{h,m}'
  s.resources             = 'Sources/Core/Resources/*'
  s.module_map            = 'Sources/Module/CMPComapiChat.modulemap'
  s.preserve_path         = 'Sources/Module/CMPComapiChat.modulemap'
  s.module_name           = s.name
  
  s.dependency 'CMPComapiFoundation'
end
