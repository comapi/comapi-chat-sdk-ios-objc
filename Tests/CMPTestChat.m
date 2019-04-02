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

#import "CMPChat.h"
#import "CMPInternalConfig.h"
#import "CMPTestMocks.h"
#import "CMPMockAuthenticationDelegate.h"
#import "CMPMockStoreFactoryBuilder.h"
#import "CMPMockChatStore.h"

#import <XCTest/XCTest.h>

@interface CMPTestChat : XCTestCase

@property (nonatomic, strong, nullable) CMPMockAuthenticationDelegate *authDelegate;
@property (nonatomic, strong, nullable) CMPMockStoreFactoryBuilder *storeFactoryBuilder;
@property (nonatomic, strong, nullable) CMPMockChatStore *chatStore;
@property (nonatomic, strong, nullable) CMPInternalConfig *internalConfig;
@property (nonatomic, strong, nullable) CMPChatConfig *config;

@end

@implementation CMPTestChat

- (void)setUp {
    _authDelegate = [[CMPMockAuthenticationDelegate alloc] init];
    _chatStore = [[CMPMockChatStore alloc] init];
    _storeFactoryBuilder = [[CMPMockStoreFactoryBuilder alloc] initWithChatStore:_chatStore];
    _internalConfig = [[CMPInternalConfig alloc] init];
    
    _config = [[CMPChatConfig alloc] initWithApiSpaceID:[CMPTestMocks mockApiSpaceID] authenticationDelegate:_authDelegate storeFactory:_storeFactoryBuilder internalConfig:_internalConfig];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testChatConfig {
    XCTAssertEqual(_config.internalConfig.maxMessagesPerPage, 10);
    XCTAssertEqual(_config.internalConfig.maxEventsPerQuery, 100);
    XCTAssertEqual(_config.internalConfig.maxEventQueries, 100);
    XCTAssertEqual(_config.internalConfig.maxPartDataSize, 13333);
    XCTAssertEqual(_config.internalConfig.maxConversationsSynced, 20);
    
    XCTAssertEqualObjects(_config.foundationConfig.authDelegate, _authDelegate);
    
    XCTAssertEqualObjects(_config.id, @"MOCK_API_SPACE_ID");
    
    XCTAssertEqualObjects(_config.foundationConfig.apiConfig.scheme, @"https");
    XCTAssertEqualObjects(_config.foundationConfig.apiConfig.host, @"api.comapi.com");
    XCTAssertEqual(_config.foundationConfig.apiConfig.port, 443);
}

- (void)testCreateChatClient {
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];
    
    [CMPChat initialiseWithConfig:_config completion:^(CMPComapiChatClient * _Nullable client) {
        XCTAssertNotNil(client);
        
        XCTAssertNil(CMPChat.shared);
        
        [exp fulfill];
    }];
    
    [self waitForExpectations:@[exp] timeout:10.0];
}

- (void)testCreateChatClientShared {
    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"callback recieved"];

    [CMPChat initialiseSharedWithConfig:_config completion:^(CMPComapiChatClient * _Nullable client) {
        XCTAssertNotNil(client);
        XCTAssertNotNil(CMPChat.shared);
        
        [exp fulfill];
    }];
    
    [self waitForExpectations:@[exp] timeout:10.0];

    
}

@end
