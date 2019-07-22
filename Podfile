platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

$env=ENV['COMAPI_XCODE_ENVIRONMENT']
$src=ENV['Build.Repository.LocalPath']
$path = "#{$src}"

target 'CMPComapiChat' do
  if $env == 'production'
    pod 'CMPComapiFoundation'
  elsif $env == 'agent' || $env == 'development'
    pod 'CMPComapiFoundation', :git => 'https://github.com/comapi/comapi-sdk-ios-objc', :branch => 'dev'
  else
    pod 'CMPComapiFoundation', :path => '/Users/dominik.kowalski/Documents/comapi-sdk-ios-objc'
  end
end

abstract_target 'Shared' do
  pod 'JWT'
  if $env == 'production'
    pod 'CMPComapiChat'
  elsif $env == 'development'
    pod 'CMPComapiChat', :git => 'https://github.com/comapi/comapi-chat-sdk-ios-objc', :branch => 'dev'
  elsif $env == 'agent'
    pod 'CMPComapiChat', :path => $path
  else
    pod 'CMPComapiChat', :path => '/Users/dominik.kowalski/Documents/comapi-chat-sdk-ios-objc'
  end
  
  target 'ComapiChatSample' do
    target 'CMPComapiChatTests' do
      inherit! :search_paths
    end
  end
end


