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

#import "CMPChatMessage.h"

@implementation CMPChatMessage

- (instancetype)initWithID:(nullable NSString *)ID sentEventID:(nullable NSNumber *)sentEventID metadata:(nullable NSDictionary<NSString *, id> *)metadata context:(nullable CMPChatMessageContext *)context parts:(nullable NSArray<CMPChatMessagePart *> *)parts statusUpdates:(nullable NSDictionary<NSString *, CMPChatMessageStatus *> *)statusUpdates {
    self = [super init];
    
    if (self) {
        self.id = ID;
        self.sentEventID = sentEventID;
        self.metadata = metadata;
        self.context = context;
        self.parts = parts;
        self.statusUpdates = statusUpdates;
    }
    
    return self;
}

- (instancetype)initWithMessage:(CMPMessage *)message {
    self = [super init];
    
    if (self) {
        self.id = message.id;
        self.sentEventID = message.sentEventID;
        self.metadata = message.metadata;
        self.context = [[CMPChatMessageContext alloc] initWithMessageContext:message.context];
        NSMutableArray<CMPChatMessagePart *> *parts = [NSMutableArray new];
        [message.parts enumerateObjectsUsingBlock:^(CMPMessagePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [parts addObject:[[CMPChatMessagePart alloc] initWithMessagePart:obj]];
        }];
        self.parts = parts;
    }
    
    return self;
}

- (instancetype)initWithSentEvent:(CMPConversationMessageEventSent *)event {
    self = [super init];
    
    if (self) {
        self.id = event.payload.messageID;
        self.sentEventID = event.conversationEventID;
        self.context = [[CMPChatMessageContext alloc] initWithMessageContext:event.payload.context];
        self.metadata = event.payload.metadata;
        NSMutableArray<CMPChatMessagePart *> *parts = [NSMutableArray new];
        [event.payload.parts enumerateObjectsUsingBlock:^(CMPMessagePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [parts addObject:[[CMPChatMessagePart alloc] initWithMessagePart:obj]];
        }];
        self.parts = parts;
    }
    
    return self;
}

- (void)addStatusUpdate:(CMPChatMessageStatus *)statusUpdate {
    NSString *unique = [NSUUID UUID].UUIDString;
    if (!_statusUpdates) {
        _statusUpdates = [NSDictionary new];
    }
    NSMutableDictionary *newDict = [NSMutableDictionary new];
    [newDict addEntriesFromDictionary:_statusUpdates];
    [newDict setValue:statusUpdate forKey:unique];
    _statusUpdates = [NSDictionary dictionaryWithDictionary:newDict];
}

#pragma mark - CMPJSONRepresentable

- (id)json {
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary new];
    
    [dict setValue:self.id forKey:@"id"];
    [dict setValue:self.sentEventID forKey:@"sentEventID"];
    [dict setValue:self.metadata forKey:@"metadata"];
    [dict setValue:[self.context json] forKey:@"context"];
    NSMutableArray<NSDictionary<NSString *, id> *> *parts = [NSMutableArray new];
    for (CMPChatMessagePart * p in self.parts) {
        [parts addObject:[p json]];
    }
    [dict setValue:parts forKey:@"parts"];
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *statusUpdates = [NSMutableDictionary new];
    [self.statusUpdates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CMPChatMessageStatus * _Nonnull obj, BOOL * _Nonnull stop) {
        statusUpdates[key] = [obj json];
    }];
    [dict setValue:statusUpdates forKey:@"statusUpdates"];
    
    return dict;
}

@end
