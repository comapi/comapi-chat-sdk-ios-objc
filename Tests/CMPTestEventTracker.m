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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "CMPMissingEventsTracker.h"
#import "CMPMissingEventsDelegate.h"

@interface CMPTestEventTracker : XCTestCase <CMPMissingEventsDelegate>

@property(nonatomic, strong) NSString *missingInConversation;
@property(nonatomic, assign) NSInteger from;
@property(nonatomic, assign) NSInteger limit;

@end

@implementation CMPTestEventTracker

- (void)setUp {
    
}

- (void)testCheckEvent {
    CMPMissingEventsTracker *tracker = [[CMPMissingEventsTracker alloc] init];

    __weak CMPTestEventTracker *weakSelf = self;
    [tracker checkEvent:@"cId" conversationEventID:@0 delegate:weakSelf];
    [tracker checkEvent:@"cId" conversationEventID:@1 delegate:weakSelf];
    [tracker checkEvent:@"cId" conversationEventID:@4 delegate:weakSelf];
    
    XCTAssertEqual(2, _from);
    XCTAssertEqual(2, _limit);
    XCTAssertTrue([_missingInConversation compare:@"cId"] == NSOrderedSame);
}

- (void)testCheckEvent2 {
    CMPMissingEventsTracker *tracker = [[CMPMissingEventsTracker alloc] init];
    
    __weak CMPTestEventTracker *weakSelf = self;
    [tracker checkEvent:@"cId" conversationEventID:@0 delegate:weakSelf];
    [tracker checkEvent:@"cId2" conversationEventID:@0 delegate:weakSelf];
    [tracker checkEvent:@"cId2" conversationEventID:@1 delegate:weakSelf];
    [tracker checkEvent:@"cId" conversationEventID:@1 delegate:weakSelf];
    [tracker checkEvent:@"cId" conversationEventID:@2 delegate:weakSelf];
    [tracker checkEvent:@"cId" conversationEventID:@8 delegate:weakSelf];
    
    XCTAssertEqual(3, _from);
    XCTAssertEqual(5, _limit);
    XCTAssertTrue([_missingInConversation compare:@"cId"] == NSOrderedSame);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _from = 0;
    _limit = 0;
    _missingInConversation = nil;
}


- (void)missingEvents:(NSString *)ID from:(NSInteger)from limit:(NSInteger)limit {
    _missingInConversation = ID;
    _from = from;
    _limit = limit;
}

@end
