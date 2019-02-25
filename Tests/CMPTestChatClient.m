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

#import "CMPComapiChatClient.h"
#import "CMPMockAuthenticationDelegate.h"
#import "CMPTestMocks.h"
#import "CMPMockRequestPerformer.h"
#import "CMPMockClientFactory.h"

#import <XCTest/XCTest.h>

#import <CMPComapiFoundation/CMPComapi.h>
#import <CMPComapiFoundation/CMPKeychain.h>

@interface CMPTestChatClient : XCTestCase

@property (nonatomic, strong, nullable) CMPComapiChatClient *client;
@property (nonatomic, strong, nullable) CMPMockRequestPerformer *requestPerformer;
@property (nonatomic, strong, nullable) CMPMockAuthenticationDelegate *authDelegate;
@property (nonatomic, strong, nullable) CMPMockStoreFactoryBuilder *storeFactoryBuilder;

@end

@implementation CMPTestChatClient

- (void)setUp {
    [super setUp];

    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionToken_", [CMPTestMocks mockApiSpaceID]]];
    [CMPKeychain deleteItemForKey:[NSString stringWithFormat:@"%@%@", @"ComapiSessionDetails_", [CMPTestMocks mockApiSpaceID]]];
    
    _requestPerformer = [[CMPMockRequestPerformer alloc] initWithSessionAndAuth];
    _authDelegate = [[CMPMockAuthenticationDelegate alloc] init];
    _storeFactoryBuilder = [[CMPMockStoreFactoryBuilder alloc] init];
    _client = [CMPMockClientFactory instantiateChatClient:_requestPerformer authDelegate:_authDelegate storeFactoryBuilder:_storeFactoryBuilder];
}

- (void)tearDown {
    _requestPerformer = nil;
    _authDelegate = nil;
    _storeFactoryBuilder = nil;
    _client = nil;
    
    [super tearDown];
}

- (void)testStartSession {
    CMPMockRequestResult *completionValue = [[CMPMockRequestResult alloc] initWithData:nil response:[NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL]] error:nil];
    [self.requestPerformer.completionValues addObject:completionValue];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    
    __weak typeof(self) weakSelf = self;
    [self.client.services.session startSessionWithCompletion:^{
        id self = weakSelf;
        XCTAssertEqualObjects(weakSelf.client.profileID, @"dominik.kowalski");
        XCTAssertEqual(weakSelf.client.sessionSuccessfullyCreated, YES);
        
        [expectation fulfill];
    } failure:^(NSError * _Nullable error) {
        XCTFail();
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testEndSession {
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:204 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *endSessionCompletionValue = [[CMPMockRequestResult alloc] initWithData:nil response:response error:nil];
    [self.requestPerformer.completionValues addObject:endSessionCompletionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.session endSessionWithCompletion:^(CMPChatResult * result) {
        XCTAssertTrue(result.isSuccessful);
        XCTAssertEqualObjects(result.error, nil);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testGetProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *endSessionCompletionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:endSessionCompletionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile getProfileForProfileID:@"" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testUpdateProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *endSessionCompletionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:endSessionCompletionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile updateProfileWithProfileID:@"" attributes:@{} eTag:@"ETag" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testPatchProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"Profile"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *endSessionCompletionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:endSessionCompletionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile patchProfileWithProfileID:@"" attributes:@{} eTag:@"ETag" completion:^(CMPResult<CMPProfile *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        
        CMPProfile *p = result.object;
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testQueryProfile {
    NSData *data = [CMPResourceLoader loadJSONWithName:@"ProfileArray"];
    NSHTTPURLResponse *response = [NSHTTPURLResponse mockedWithURL:[CMPTestMocks mockBaseURL] statusCode:200 httpVersion:@"HTTP/1.1" headers:@{}];
    CMPMockRequestResult *endSessionCompletionValue = [[CMPMockRequestResult alloc] initWithData:data response:response error:nil];
    [self.requestPerformer.completionValues addObject:endSessionCompletionValue];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"callback received"];
    [self.client.services.profile queryProfilesWithQueryElements:@[] completion:^(CMPResult<NSArray<CMPProfile *> *> * _Nonnull result) {
        XCTAssertTrue(result.error == nil);
        XCTAssertTrue(result.object != nil);
        XCTAssertTrue(result.object.count > 0);
        
        CMPProfile *p = result.object[0];
        XCTAssertEqualObjects(p.firstName, @"Dominik");
        XCTAssertEqualObjects(p.lastName, @"Kowalski");
        XCTAssertEqualObjects(p.email, @"test@mail.com");
        XCTAssertEqualObjects(p.phoneNumber, @"48222222222");
        XCTAssertEqualObjects(p.phoneNumberCountryCode, @"PL");
        XCTAssertEqualObjects(p.id, @"90419e09-1f5b-4fc2-97c8-b878793c53f0");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSendMessage {
    
}

@end
