platform :ios, '10.0'
use_frameworks!

def shared
pod 'CMPComapiFoundation', :git => 'https://github.com/comapi/comapi-sdk-ios-objc.git', :branch => 'dev'
end

target 'CMPComapiChat' do

shared

end

target 'SampleApp' do

shared
pod 'CMPComapiChat', :path => '/Users/dominik.kowalski/Documents/comapi-chat-sdk-ios-objc'

end
