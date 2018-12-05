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

#import "CMPConversationComparison.h"

#import "CMPChatConversation.h"

@import CMPComapiFoundation;

@implementation CMPConversationComparison

- (instancetype)initFrom:(NSDictionary<NSString *,CMPConversation *> *)downloadedList savedList:(NSDictionary<NSString *,CMPChatConversation *> *)savedList isSuccessful:(BOOL)isSuccessful {
    self = [super init];
    
    if (self) {
        _remoteCallSuccessful = isSuccessful;
        _conversationsToAdd = [NSMutableArray new];
        _conversationsToDelete = [NSMutableArray new];
        _conversationsToUpdate = [NSMutableArray new];

        NSMutableDictionary<NSString *, CMPChatConversation *> * savedListProcessed = [NSMutableDictionary dictionaryWithDictionary:savedList];
        
        for (NSString *key in downloadedList.allKeys) {
            if ([savedListProcessed objectForKey:key]) {
                CMPChatConversation *saved = [savedListProcessed objectForKey:key];
                if (saved.lastLocalEventID.integerValue != -1) {
                    CMPChatConversation *converastionToUpdate = [[CMPChatConversation alloc] initWithConversation:[downloadedList objectForKey:key]];
                    converastionToUpdate.firstLocalEventID = saved.firstLocalEventID;
                    converastionToUpdate.lastLocalEventID = saved.lastLocalEventID;
                    [_conversationsToUpdate addObject:converastionToUpdate];
                }
            } else {
                CMPChatConversation *converastionToAdd = [[CMPChatConversation alloc] initWithConversation:[downloadedList objectForKey:key]];
                [_conversationsToAdd addObject:converastionToAdd];
            }
            
            [savedListProcessed removeObjectForKey:key];
        }
        
        if (savedListProcessed.count != 0) {
            [_conversationsToDelete addObjectsFromArray:savedListProcessed.allValues];
        }
    }
    
    return self;
}

- (instancetype)initFrom:(NSNumber *)latestRemoteEventID conversation:(CMPChatConversation *)conversation {
    self = [super init];
    
    if (self) {
        _remoteCallSuccessful = true;
        _conversationsToAdd = [NSMutableArray new];
        _conversationsToDelete = [NSMutableArray new];
        _conversationsToUpdate = [NSMutableArray new];
        
        if (conversation != nil && latestRemoteEventID != nil) {
            if (conversation.latestRemoteEventID != nil && conversation.latestRemoteEventID.integerValue != -1 && latestRemoteEventID.integerValue > conversation.latestRemoteEventID.integerValue) {
                CMPChatConversation *conversationToUpdate = [conversation copy];
                conversationToUpdate.latestRemoteEventID = latestRemoteEventID;
                [_conversationsToUpdate addObject:conversationToUpdate];
            }
        }
        
        if (latestRemoteEventID == nil || latestRemoteEventID.integerValue == -1) {
            _remoteCallSuccessful = false;
        }
    }
    
    return self;
}

- (void)addSuccess:(BOOL)success {
    _isSuccessful = success && _remoteCallSuccessful;
}

@end
