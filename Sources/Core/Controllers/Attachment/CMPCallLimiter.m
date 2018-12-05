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

#import "CMPCallLimiter.h"

@interface CMPCallLimiter ()

@property (nonatomic, readonly) NSTimeInterval largeTimeFrame;
@property (nonatomic, readonly) NSInteger largeCallsLimit;
@property (nonatomic, readonly) NSTimeInterval smallTimeFrame;
@property (nonatomic, readonly) NSInteger smallCallLimit;

@property (nonatomic, readonly) NSTimeInterval shutdownPeriod;

@property (nonatomic, readwrite) NSTimeInterval shutdownEndTime;

@property (nonatomic, readwrite) BOOL isShutdown;

@property (nonatomic, readwrite) NSTimeInterval largeLimitTimestamp;
@property (nonatomic, readwrite) NSTimeInterval largeLimitCalls;

@property (nonatomic, readwrite) NSTimeInterval smallLimitTimestamp;
@property (nonatomic, readwrite) NSTimeInterval smallLimitCalls;

@end

@implementation CMPCallLimiter

- (instancetype)initWithLargeTimeFrame:(NSTimeInterval)largeTimeFrame largeCallsLimit:(NSInteger)largeCallsLimit smallTimeFrame:(NSTimeInterval)smallTimeFrame smallCallLimit:(NSInteger)smallCallLimit shutdownPeriod:(NSTimeInterval)shutdownPeriod {
    self = [super init];
    
    if (self) {
        _largeTimeFrame = largeTimeFrame;
        _largeCallsLimit = largeCallsLimit;
        
        _smallTimeFrame = smallTimeFrame;
        _smallLimitCalls = smallCallLimit;
        
        _shutdownPeriod = shutdownPeriod;
        
        _largeLimitTimestamp = [[NSDate date] timeIntervalSince1970] + largeTimeFrame;
    }
    
    return self;
}

- (BOOL)checkAndIncrease {
    NSTimeInterval newTimestamp = [[NSDate date] timeIntervalSince1970];
    
    if (_isShutdown) {
        if (newTimestamp > _shutdownEndTime) {
            _isShutdown = NO;
            _largeLimitCalls = 0;
            _smallLimitCalls = 0;
        } else {
            return NO;
        }
    }
    
    if (newTimestamp - _largeLimitTimestamp > _largeTimeFrame) {
        _largeLimitCalls = 0;
        _largeLimitTimestamp = newTimestamp;
    } else {
        if (_largeLimitCalls >= _largeCallsLimit) {
            _isShutdown = YES;
            _shutdownEndTime = newTimestamp + _shutdownPeriod;
            return NO;
        } else {
            _largeLimitCalls += 1;
        }
    }
    
    return YES;
}

@end
