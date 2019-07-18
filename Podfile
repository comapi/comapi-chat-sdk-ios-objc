platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'CMPComapiChat' do
  pod 'CMPComapiFoundation', :path => '/Users/dominik.kowalski/Documents/comapi-sdk-ios-objc'
end

abstract_target 'Shared' do
  pod 'JWT'
  pod 'CMPComapiChat', :path => '/Users/dominik.kowalski/Documents/comapi-chat-sdk-ios-objc'
  
  target 'ComapiChatSample' do
    target 'CMPComapiChatTests' do
      inherit! :search_paths
    end
  end
end


