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

#import "CMPMissingEventsTracker.h"

@interface CMPMissingEventsTracker ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *idsPerConverastion;

@end

@implementation CMPMissingEventsTracker

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _idsPerConverastion = [NSMutableDictionary new];
    }
    
    return self;
}

- (BOOL)checkEventForConversationID:(NSString *)conversationID conversationEventID:(NSNumber *)conversationEventID delegate:(id<CMPMissingEventsDelegate>)delegate {
    if (_idsPerConverastion[conversationID] == nil) {
        NSMutableArray<NSNumber *> *ids = [NSMutableArray new];
        [ids addObject:conversationEventID];
        @synchronized(_idsPerConverastion) {
            _idsPerConverastion[conversationID] = ids;
        }
        return NO;
    } else {
        @synchronized(_idsPerConverastion) {
            NSMutableArray<NSNumber *> *ids = _idsPerConverastion[conversationID];
            NSNumber *last = [ids lastObject];
            
            BOOL added = NO;
            if (![ids containsObject:conversationEventID]) {
                added = YES;
                [ids addObject:conversationEventID];
            }
            
            if (last.integerValue < conversationEventID.integerValue - 1) {
                [delegate missingEventsForID:conversationID from:last.integerValue + 1 limit:conversationEventID.integerValue - last.integerValue];
            }
            
            while (ids.count > 10) {
                [ids removeObjectAtIndex:0];
            }
            
            return added;
        }
    }
}

@end
