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

#import "CMPModelAdapter.h"
#import "CMPEventParser.h"
#import "CMPConversationMessageEvents.h"

@implementation CMPModelAdapter

- (NSArray<CMPChatMessageStatus *> *)adaptStatusesForConversationID:(NSString *)conversationID messageID:(NSString *)messageID statuses:(NSDictionary<NSString *,CMPMessageStatus *> *)statuses {
    NSMutableArray<CMPChatMessageStatus *> *adapted = [NSMutableArray new];
    
    [statuses enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CMPMessageStatus * _Nonnull obj, BOOL * _Nonnull stop) {
        CMPChatMessageDeliveryStatus status = [CMPChatMessageDeliveryStatusParser parseStatus:obj.status];
        CMPChatMessageStatus *messageStatus = [[CMPChatMessageStatus alloc] initWithConversationID:conversationID messageID:messageID profileID:key conversationEventID:nil timestamp:obj.timestamp messageStatus:status];
        [adapted addObject:messageStatus];
    }];
    
    return adapted;
}

- (NSArray<CMPChatMessageParticipant *> *)adaptParticipants:(NSArray<CMPMessageParticipant *> *)participants {
    NSMutableArray<CMPChatMessageParticipant *> *adapted = [NSMutableArray new];
    
    [participants enumerateObjectsUsingBlock:^(CMPMessageParticipant * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [adapted addObject:[[CMPChatMessageParticipant alloc] initWithMessageParticipant:obj]];
    }];
    
    return adapted;
}

- (NSArray<CMPChatMessage *> *)adaptMessages:(NSArray<CMPMessage *> *)messages {
    NSMutableArray<CMPChatMessage *> *adapted = [NSMutableArray new];
    
    [messages enumerateObjectsUsingBlock:^(CMPMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [adapted addObject:[[CMPChatMessage alloc] initWithMessage:obj]];
    }];
    
    return adapted;
}

- (NSArray<CMPMessagePart *> *)adaptChatMessageParts:(NSArray<CMPChatMessagePart *> *)parts {
    NSMutableArray<CMPMessagePart *> *adapted = [NSMutableArray new];
    
    [parts enumerateObjectsUsingBlock:^(CMPChatMessagePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [adapted addObject:[[CMPMessagePart alloc] initWithName:obj.name type:obj.type url:obj.url data:obj.data size:obj.size]];
    }];
    
    return adapted;
}

- (NSArray<CMPChatMessagePart *> *)adaptMessageParts:(NSArray<CMPMessagePart *> *)parts {
    NSMutableArray<CMPChatMessagePart *> *adapted = [NSMutableArray new];
    
    [parts enumerateObjectsUsingBlock:^(CMPMessagePart * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [adapted addObject:[[CMPChatMessagePart alloc] initWithName:obj.name type:obj.type url:obj.url data:obj.data size:obj.size]];
    }];
    
    return adapted;
}

- (NSArray<CMPChatMessageStatus *> *)adaptEvents:(NSArray<CMPChatManagedOrphanedEvent *> *)events {
    NSMutableArray<CMPChatMessageStatus *> *adapted = [NSMutableArray new];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    
    [events enumerateObjectsUsingBlock:^(CMPChatManagedOrphanedEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        switch (obj.eventType) {
            case CMPChatMessageDeliveryStatusRead: {
                CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithConversationID:obj.conversationID messageID:obj.messageID profileID:obj.profileID conversationEventID:[formatter numberFromString:obj.eventID] timestamp:obj.timestamp messageStatus:CMPChatMessageDeliveryStatusRead];
                [adapted addObject:status];
                break;
            }
            case CMPEventTypeConversationMessageDelivered: {
                CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithConversationID:obj.conversationID messageID:obj.messageID profileID:obj.profileID conversationEventID:[formatter numberFromString:obj.eventID] timestamp:obj.timestamp messageStatus:CMPChatMessageDeliveryStatusDelivered];
                [adapted addObject:status];
                break;
            }
            default:
                break;
        }
    }];
    
    return adapted;
}

@end
