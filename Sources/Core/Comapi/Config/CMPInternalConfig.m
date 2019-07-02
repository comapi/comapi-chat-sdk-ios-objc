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

#import "CMPInternalConfig.h"

NSInteger const kDefaultMessagesPerPage = 10;
NSInteger const kDefaultEventsPerQuery = 100;
NSInteger const kDefaultEventQueries = 100;
NSInteger const kDefaultPartDataSize = 13333;
NSInteger const kDefaultConversationSynced = 20;

@implementation CMPInternalConfig

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.maxMessagesPerPage = kDefaultMessagesPerPage;
        self.maxEventsPerQuery = kDefaultEventsPerQuery;
        self.maxEventQueries = kDefaultEventQueries;
        self.maxPartDataSize = kDefaultPartDataSize;
        self.maxConversationsSynced = kDefaultConversationSynced;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Max messages per conversation: %ld\n Max events per query: %ld\n Max event queries: %ld\n Max data part size: %ld\n Max conversations synced: %ld", (long)self.maxMessagesPerPage, (long)self.maxEventsPerQuery, (long)self.maxEventQueries, (long)self.maxPartDataSize, (long)self.maxConversationsSynced];
}

@end
