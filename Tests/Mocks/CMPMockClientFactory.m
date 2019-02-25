//
// The MIT License (MIT)
// Copyright (c) 2017 Comapi (trading name of Dynmark International Limited)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
// to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CMPMockClientFactory.h"

@interface CMPMockClientFactory ()



@end

@interface CMPComapiClient ()

- (instancetype)initWithApiSpaceID:(NSString *)apiSpaceID authenticationDelegate:(id<CMPAuthenticationDelegate>)delegate apiConfiguration:(CMPAPIConfiguration *)configuration;
- (instancetype)initWithApiSpaceID:(NSString *)apiSpaceID authenticationDelegate:(id<CMPAuthenticationDelegate>)delegate apiConfiguration:(CMPAPIConfiguration *)configuration requestPerformer:(id<CMPRequestPerforming>)requestPerformer;

@end

@implementation CMPMockClientFactory

+ (CMPComapiChatClient *)instantiateChatClient:(id<CMPRequestPerforming>)requestPerformer authDelegate:(nonnull id<CMPAuthenticationDelegate>)authDelegate storeFactoryBuilder:(id<CMPStoreFactoryBuildable>)storeFactoryBuilder {
    CMPInternalConfig *internalConfig = [[CMPInternalConfig alloc] init];
    CMPAPIConfiguration *apiConfig = [[CMPAPIConfiguration alloc] initWithScheme:@"https" host:@"stage-api.comapi.com" port:443];
    CMPStoreFactory *mockStoreFactory = [[CMPStoreFactory alloc] initWithBuilder:storeFactoryBuilder];
    CMPChatConfig *config = [[CMPChatConfig alloc] initWithApiSpaceID:[CMPTestMocks mockApiSpaceID] authenticationDelegate:authDelegate storeFactory:mockStoreFactory internalConfig:internalConfig];
    CMPComapiClient *foundationMockClient = [[CMPComapiClient alloc] initWithApiSpaceID:[CMPTestMocks mockApiSpaceID] authenticationDelegate:authDelegate apiConfiguration:apiConfig requestPerformer:requestPerformer];
    CMPComapiChatClient *mockChatClient = [[CMPComapiChatClient alloc] initWithClient:foundationMockClient chatConfig:config];
    
    return mockChatClient;
}

@end