platform :ios, '10.0'
use_frameworks!

def shared
pod 'CMPComapiFoundation'
end

target 'CMPComapiChat' do

shared

end

target 'CMPComapiChatTests' do

shared
pod 'CMPComapiChat', :path => '/Users/dominik.kowalski/Documents/comapi-chat-sdk-ios-objc'

end

target 'SampleApp' do

shared
pod 'CMPComapiChat', :path => '/Users/dominik.kowalski/Documents/comapi-chat-sdk-ios-objc'

end
