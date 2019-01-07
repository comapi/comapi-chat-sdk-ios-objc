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

#import "CMPEventsController.h"
#import "CMPChatConversation.h"

#import <CMPComapiFoundation/CMPEvent.h>
#import <CMPComapiFoundation/CMPConversationMessageEvents.h>

@interface CMPEventsController ()

@property (nonatomic, weak, readonly) CMPPersistenceController *persistenceController;
@property (nonatomic, weak, readonly) CMPChatController *chatController;
@property (nonatomic, weak, readonly) CMPMissingEventsTracker *tracker;
@property (nonatomic, weak, readonly) id<CMPMissingEventsDelegate> delegate;

@end

@implementation CMPEventsController

- (instancetype)initWithPersistenceController:(CMPPersistenceController *)persistenceController chatController:(CMPChatController *)chatController missingEventsTracker:(CMPMissingEventsTracker *)tracker chatConfig:(CMPChatConfig *)config {
    self = [super init];
    
    if (self) {
        _persistenceController = persistenceController;
        _chatController = chatController;
        _tracker = tracker;
    }
    
    return self;
}

#pragma mark - CMPMissingEventsDelegate

- (void)missingEventsForID:(NSString *)ID from:(NSInteger)from limit:(NSInteger)limit {
    [_chatController queryMissingEventsForConversationID:ID from:from limit:limit];
}

#pragma mark - CMPStateDelegate

- (void)didConnectSocket {
    [_chatController handleSocketConnected];
}

- (void)didDisconnectSocketWithError:(NSError * _Nullable)error {
    [_chatController handleSocketDisconnectedWithError:error];
}

- (void)didEndSessionWithError:(NSError * _Nullable)error {}

- (void)didStartSession {}

#pragma mark - CMPEventDelegate

- (void)client:(nonnull CMPComapiClient *)client didReceiveEvent:(nonnull CMPEvent *)event {
    switch (event.type) {
        case CMPEventTypeConversationCreate: {
            CMPChatConversation *conversation = [[CMPChatConversation alloc] initWithConversationCreateEvent:(CMPConversationEventCreate *)event];
            if (conversation) {
                [_persistenceController upsertConversations:@[conversation] completion:^(BOOL success, NSError * _Nullable error) {
                    
                }];
            }
            break;
        }
        case CMPEventTypeConversationUpdate: {
            CMPChatConversation *conversation = [[CMPChatConversation alloc] initWithConversationUpdateEvent:(CMPConversationEventUpdate *)event];
            if (conversation) {
                [_persistenceController upsertConversations:@[conversation] completion:^(BOOL success, NSError * _Nullable error) {
                    
                }];
            }
            break;
        }
        case CMPEventTypeConversationDelete:
            break;
        case CMPEventTypeConversationUndelete: {
            CMPChatConversation *conversation = [[CMPChatConversation alloc] initWithConversationUndeleteEvent:(CMPConversationEventUndelete *)event];
            if (conversation) {
                [_persistenceController upsertConversations:@[conversation] completion:^(BOOL success, NSError * _Nullable error) {
                    
                }];
            }
            break;
        }
        case CMPEventTypeConversationParticipantAdded: {
            
            break;
        }
            
        case CMPEventTypeConversationParticipantRemoved:
            
            break;
        case CMPEventTypeConversationParticipantUpdated:
            
            break;
        case CMPEventTypeConversationParticipantTyping:
            
            break;
        case CMPEventTypeConversationParticipantTypingOff:
            
            break;
        case CMPEventTypeSocketInfo:
            break;
        case CMPEventTypeProfileUpdate:
            break;
        case CMPEventTypeConversationMessageDelivered:
            break;
        case CMPEventTypeConversationMessageSent: {
            CMPConversationMessageEventSent *e = (CMPConversationMessageEventSent *)event;
            [_tracker checkEventForConversationID:e.payload.context.conversationID conversationEventID:e.conversationEventID delegate:self];
            [_chatController handleMessage:[[CMPChatMessage alloc] init] completion:^(BOOL success, NSError * _Nullable error) {
                
            }];
            break;
        }
        case CMPEventTypeConversationMessageRead: {
            
        }
            break;
            
        case CMPEventTypeNone:
            break;
    }
}
//    class MessagingListenerAdapter extends MessagingListener {
//
//        @Override
//        public void onMessage(MessageSentEvent event) {
//            tracker.checkEventId(event.getContext().getConversationId(), event.getConversationEventId(), missingEventsListener);
//            observableExecutor.execute(controller.handleMessage(ChatMessage.builder().populate(event).build()));
//        }
//
//        /**
//         * Dispatch conversation message update event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onMessageDelivered(MessageDeliveredEvent event) {
//            tracker.checkEventId(event.getConversationId(), event.getConversationEventId(), missingEventsListener);
//            observableExecutor.execute(persistenceController.upsertMessageStatus(ChatMessageStatus.builder().populate(event).build()));
//        }
//
//        /**
//         * Dispatch conversation message update event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onMessageRead(MessageReadEvent event) {
//            tracker.checkEventId(event.getConversationId(), event.getConversationEventId(), missingEventsListener);
//            observableExecutor.execute(persistenceController.upsertMessageStatus(ChatMessageStatus.builder().populate(event).build()));
//        }
//
//        /**
//         * Dispatch participant added to a conversation event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onParticipantAdded(ParticipantAddedEvent event) {
//            observableExecutor.execute(controller.handleParticipantsAdded(event.getConversationId()));
//        }
//
//        /**
//         * Dispatch conversation updated event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onConversationUpdated(ConversationUpdateEvent event) {
//            observableExecutor.execute(persistenceController.upsertConversation(ChatConversation.builder().populate(event).build()));
//        }
//
//        /**
//         * Dispatch conversation deleted event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onConversationDeleted(ConversationDeleteEvent event) {
//            observableExecutor.execute(persistenceController.deleteConversation(event.getConversationId()));
//        }
//
//        /**
//         * Dispatch conversation restored event.
//         *
//         * @param event Event to dispatch.
//         */
//        @Override
//        public void onConversationUndeleted(ConversationUndeleteEvent event) {
//            observableExecutor.execute(persistenceController.upsertConversation(ChatConversation.builder().populate(event).build()));
//        }
//    }
//}



@end
