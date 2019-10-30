platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

$env=ENV['COMAPI_XCODE_ENVIRONMENT']

abstract_target 'Shared' do
  if $env == 'production'
    pod 'CMPComapiFoundation'
  elsif $env == 'agent' || $env == 'development'
    pod 'CMPComapiFoundation', :git => 'https://github.com/comapi/comapi-sdk-ios-objc', :branch => 'dev'
  else
    src=ENV['FOUNDATION_REPOSITORY_LOCALPATH']
    path = "#{src}"
    pod 'CMPComapiFoundation', :path => path
  end

  target 'CMPComapiChat' do
    target 'ComapiChatSample' do
      pod 'JWT'

      target 'CMPComapiChatTests'
    end
  end
end


