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

#import "CMPChatController.h"
#import "CMPCallLimiter.h"
#import "CMPChatAttachment.h"
#import "CMPMessageProcessor.h"
#import "CMPChatResult.h"
#import "CMPRetryManager.h"

#import <CMPComapiFoundation/CMPConversationMessageEvents.h>
#import <CMPComapiFoundation/CMPMessageStatusUpdate.h>
#import <CMPComapiFoundation/CMPLogger.h>

NSInteger const kETagNotValid = 412;

@interface CMPChatController ()

@property (nonatomic, readonly) NSInteger messagesPerQuery;
@property (nonatomic, readonly) NSInteger eventsPerQuery;
@property (nonatomic) NSInteger maxEventQueries;
@property (nonatomic) NSInteger maxConversationsSynced;

@property (nonatomic, weak, nullable, readonly) CMPComapiClient *client;

@property (nonatomic, strong, readonly) CMPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) CMPAttachmentController *attachmentController;

@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;
@property (nonatomic, strong, readonly) CMPInternalConfig *config;
@property (nonatomic, strong, readonly) CMPCallLimiter *callLimiter;

@property (atomic) BOOL isSynchronising;
@property (atomic) BOOL socketWasDisconnected;

- (nullable CMPComapiClient *)withClient;

@end

@implementation CMPChatController

- (instancetype)initWithClient:(CMPComapiClient *)client persistenceController:(CMPPersistenceController *)persistenceController attachmentController:(CMPAttachmentController *)attachmentController adapter:(CMPModelAdapter *)adapter config:(CMPInternalConfig *)config callLimiter:(CMPCallLimiter *)callLimiter {
    self = [super init];
    
    if (self) {
        _isSynchronising = NO;
        _socketWasDisconnected = NO;
        
        _adapter = adapter;
        _config = config;
        
        _persistenceController = persistenceController;
        _attachmentController = attachmentController;
        
        _messagesPerQuery = config.maxMessagesPerPage;
        _eventsPerQuery = config.maxEventsPerQuery;
        _maxEventQueries = config.maxEventQueries;
        _maxConversationsSynced = config.maxConversationsSynced;

        _callLimiter = [[CMPCallLimiter alloc] initWithLargeTimeFrame:30 * 60 largeCallsLimit:50 smallTimeFrame:5 * 60 smallCallLimit:15 shutdownPeriod:60 * 60];
    }
    
    return self;
}

#pragma mark - Internal

- (nullable CMPComapiClient *)withClient {
    if (_client) {
        return _client;
    } else {
        logWithLevel(CMPLogLevelError, @"Client is nil, returning...", nil);
        return nil;
    }
}

- (nullable NSString *)getProfileID {
    return [self withClient] != nil ? [[self withClient] getProfileID] : nil;
}

#pragma mark - Store

///**
// * Check state for all conversations and update from services.
// *
// * @return Result of synchronisation process.
// */
//Observable<ChatResult> synchroniseStore() {
//    if (isSynchronising.getAndSet(true)) {
//        log.i("Synchronisation in progress.");
//        return Observable.fromCallable(() -> new ChatResult(true, null));
//    }
//    log.i("Synchronising store.");
//    return synchroniseConversations()
//    .onErrorReturn(t -> new ChatResult(false, new ChatResult.Error(0, t)))
//    .doOnNext(i -> {
//        if (i.isSuccessful()) {
//            log.i("Synchronisation successfully finished.");
//        } else {
//            log.e("Synchronisation finished with error. " + (i.getError() != null ? i.getError().getMessage() : ""));
//        }
//        isSynchronising.compareAndSet(true, false);
//    });
//}

- (void)synchronizeStore {
    // TODO: -
}

#pragma mark - Sockets

- (void)handleSocketConnected {
    _socketWasDisconnected = NO;
    if ([_callLimiter checkAndIncrease]) {
        
    }
}

- (void)handleSocketDisconnectedWithError:(NSError *)error {
    _socketWasDisconnected = YES;
}

#pragma mark - Messages

- (void) sendMessage: (nonnull CMPChatMessage *) message withAttachments: (nullable NSArray<CMPChatAttachment *> *) attachments toConversationWithID: (nonnull NSString *) conversationId from:(NSString *) from {
    //CMPMessageProcessor *processor = [[CMPMessageProcessor alloc] initWithMessage:message toConversationWithID:conversationId from:from];
    //CMPChatMessage *messageToSave = [processor createPreUploadMessageWithAttachments:attachments];
    // save message
    // send attachments
    //CMPChatMessage *messageToUpdate = [processor createPostUploadMessageWithAttachments:attachments];
    // save message
    // send message
    // update id with processor.tempMessageId and eventId
    
}

- (void)handleMessage:(CMPChatMessage *)message completion:(void(^)(BOOL, NSError * _Nullable))completion {
    NSString *sender = message.context.sentBy;
    
    __block BOOL updateStoreSuccess;
    __block CMPChatResult *markDeliveredResult;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [_persistenceController updateStoreWithNewMessage:message completion:^(BOOL success, NSError * _Nullable error) {
        updateStoreSuccess = success;
        dispatch_group_leave(group);
    }];
    
    
    if (sender != nil && ![sender isEqualToString:@""] && [sender isEqualToString:[self getProfileID]]) {
        NSArray<NSString *> *ids = [NSArray arrayWithObjects:message.id, nil];
        
        dispatch_group_enter(group);
        [self markDelivered:message.context.conversationID messageIDs:ids completion:^(CMPChatResult * result) {
            markDeliveredResult = result;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(updateStoreSuccess && markDeliveredResult.isSuccessful, markDeliveredResult.error);
    });
}

- (void)getPreviousMessages:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [_persistenceController getConversationForID:ID completion:^(CMPChatConversation * conversation, NSError * _Nullable error) {
        if (error) {
            completion([[CMPChatResult alloc] initWithError:error success:NO]);
        } else if (conversation) {
            NSNumber *from = conversation.firstLocalEventID;
            NSNumber *queryFrom;
            if (from) {
                if ([from isEqualToNumber:@(0)]) {
                    completion([[CMPChatResult alloc] initWithError:nil success:YES]);
                } else if (from.integerValue > 0) {
                    queryFrom = @(from.integerValue - 1);
                }
            }
            [[weakSelf withClient].services.messaging getMessagesWithConversationID:ID from:queryFrom.integerValue completion:^(CMPResult<CMPGetMessagesResult *> * result) {
                if (result.error) {
                    completion([[CMPChatResult alloc] initWithError:error success:NO]);
                } else {
                    [weakSelf.persistenceController processMessagesResultForID:ID result:result.object completion:^(CMPGetMessagesResult * result, NSError * error) {
                        if (error) {
                            completion([[CMPChatResult alloc] initWithError:error success:NO]);
                        } else {
                            [weakSelf.persistenceController processOrphanedEvents:result completion:^(NSError * _Nullable error) {
                                completion([[CMPChatResult alloc] initWithError:error success:error == nil]);
                            }];
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)handleMessageStatusToUpdateForID:(NSString *)ID statusUpdates:(NSArray<CMPMessageStatusUpdate *> *)statusUpdates result:(CMPResult *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error && statusUpdates.count > 0) {
        [_persistenceController upsertMessageStatusesForConversationID:ID profileID:[self getProfileID] statuses:statusUpdates completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    }
}

- (void)markDelivered:(NSString *)ID messageIDs:(NSArray<NSString *> *)IDs completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [CMPRetryManager retryBlock:^(void (^successBlock)(BOOL)) {
        [[weakSelf withClient].services.messaging updateStatusForMessagesWithIDs:IDs status:CMPMessageDeliveryStatusDelivered conversationID:ID timestamp:[NSDate date] completion:^(CMPResult<NSNumber *> * result) {
            BOOL success = !result.error && result.object;
            successBlock(success);
            if (success) {
                completion([[CMPChatResult alloc] initWithComapiResult:result]);
            }
        }];
    } attempts:3 interval:3];
}

- (void)upsertTempMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
    [_persistenceController updateStoreWithNewMessage:message completion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            logWithLevel(CMPLogLevelError, @"Error saving temp message: %@", error.localizedDescription, nil);
        }
        completion(success);
    }];
}

///**
// * Handles message send service response. Will delete temporary message object. Same message but with correct message id will be inserted instead.
// *
// * @param mp       Message processor holding message sending details.
// * @param response Service call response.
// * @return Observable emitting result of operations.
// */
//Observable<ChatResult> updateStoreWithSentMsg(MessageProcessor mp, ComapiResult<MessageSentResponse> response) {
//    if (response.isSuccessful()) {
//        return persistenceController.updateStoreWithNewMessage(mp.createFinalMessage(response.getResult()), noConversationListener).map(success -> adapter.adaptResult(response, success));
//    } else {
//        return Observable.fromCallable(() -> adapter.adaptResult(response));
//    }
//}

- (void)updateStoreWithSentMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
    // TODO: -
}

///**
// * Handle failure when sending message.
// *
// * @param mp Message processor holding message sending details.
// * @param t  Thrown exception.
// * @return Observable with Chat SDK result.
// */
//private Observable<ChatResult> handleMessageError(MessageProcessor mp, Throwable t) {
//    return persistenceController.updateStoreForSentError(mp.getConversationId(), mp.getTempId(), mp.getSender())
//    .map(success -> new ChatResult(false, new ChatResult.Error(0, t)));
//}

- (void)handleMessageError {
    // TODO: -
}

///**
// * Save and send message with attachments.
// *
// * @param conversationId Unique conversation id.
// * @param message        Message to send
// * @param attachments    List of attachments to send with a message.
// * @return Observable with Chat SDK result.
// */
//Observable<ChatResult> sendMessageWithAttachments(@NonNull final String conversationId, @NonNull final MessageToSend message, @Nullable final List<Attachment> attachments) {
//
//    final MessageProcessor messageProcessor = attCon.createMessageProcessor(message, attachments, conversationId, getProfileId());
//
//    return checkState()
//    .flatMap(client ->
//             {
//                 messageProcessor.preparePreUpload(); // convert fom too large message parts to attachments, adds temp upload parts for all attachments
//                 return upsertTempMessage(messageProcessor.createTempMessage()) // create temporary message
//                 .flatMap(isOk -> attCon.uploadAttachments(messageProcessor.getAttachments(), client)) // upload attachments
//                 .flatMap(uploaded -> {
//                     if (uploaded != null && !uploaded.isEmpty()) {
//                         messageProcessor.preparePostUpload(uploaded); // remove temp upload parts, add parts with upload data
//                         return upsertTempMessage(messageProcessor.createTempMessage()); // update message with attachments details like url
//                     } else {
//                         return Observable.fromCallable(() -> true);
//                     }
//                 })
//                 .flatMap(isOk -> client.service().messaging().sendMessage(conversationId, messageProcessor.prepareMessageToSend()) // send message with attachments details as additional message parts
//                          .flatMap(result -> updateStoreWithSentMsg(messageProcessor, result)) // update temporary message with a new message id obtained from the response
//                          .onErrorResumeNext(t -> handleMessageError(messageProcessor, t))); // if error occurred update message status list adding error status
//             });

- (void)sendMessageWithAttachments:(NSString *)conversationID message:(CMPSendableMessage *)message {
    // TODO: -
}

#pragma mark - Conversations

///**
// * Updates single conversation state.
// *
// * @return Result of synchronisation with services.
// */
//Observable<ChatResult> synchroniseConversation(String conversationId) {
//
//    return checkState().flatMap(client -> client.service().messaging()
//                                .queryMessages(conversationId, null, 1)
//                                .map(result -> {
//        if (result.isSuccessful() && result.getResult() != null) {
//            return (long) result.getResult().getLatestEventId();
//        }
//        return -1L;
//    })
//                                .flatMap(result -> persistenceController.getConversation(conversationId).map(loaded -> compare(result, loaded)))
//                                .flatMap(this::updateLocalConversationList)
//                                .flatMap(result -> lookForMissingEvents(client, result))
//                                .map(result -> new ChatResult(result.isSuccessful, null)));
//}

- (void)synchroniseConversation {
    // TODO: -
}

///**
// * Update list of local conversations.
// *
// * @param conversationComparison Describes differences in local and remote participant list.
// * @return Observable returning unchanged argument to further processing.
// */
//private Observable<ConversationComparison> updateLocalConversationList(final ConversationComparison conversationComparison) {
//
//    return Observable.zip(persistenceController.deleteConversations(conversationComparison.conversationsToDelete),
//                          persistenceController.upsertConversations(conversationComparison.conversationsToAdd),
//                          persistenceController.updateConversations(conversationComparison.conversationsToUpdate),
//                          (success1, success2, success3) -> success1 && success2 && success3)
//    .map(result -> {
//        conversationComparison.addSuccess(result);
//        return conversationComparison;
//    });
//}

- (void)updateLocalConversationList {
    // TODO: -
}

///**
// * Updates all conversation states.
// *
// * @return Result of synchronisation with services.
// */
//private Observable<ChatResult> synchroniseConversations() {
//
//    return checkState().flatMap(client -> client.service().messaging()
//                                .getConversations(false)
//                                .flatMap(result -> persistenceController.loadAllConversations()
//                                         .map(chatConversationBases -> compare(result.isSuccessful(), result.getResult(), chatConversationBases)))
//                                .flatMap(this::updateLocalConversationList)
//                                .flatMap(result -> lookForMissingEvents(client, result))
//                                .map(result -> new ChatResult(result.isSuccessful, null)));
//}

- (void)synchronizeConversationsWithCompletion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging getConversationsWithProfileID:[self getProfileID] isPublic:NO completion:^(CMPResult<NSArray<CMPConversation *> *> * result) {
        [weakSelf.persistenceController getAllConversationsWithCompletion:^(NSArray<CMPChatConversation *> * _Nullable conversations, NSError * _Nullable error) {
            // TODO: -
        }];
    }];
}

- (NSArray<CMPChatConversation *> *)limitNumberOfConversations:(NSArray<CMPChatConversation *> *)conversations {
    NSMutableArray<CMPChatConversation *> *nonEmptyConversations = [NSMutableArray new];
    
    [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.latestRemoteEventID != nil && [obj.latestRemoteEventID integerValue] >= 0) {
            [nonEmptyConversations addObject:obj];
        }
    }];
    
    NSMutableArray<CMPChatConversation *> *limitedList = [NSMutableArray new];
    
    if (nonEmptyConversations.count <= _maxConversationsSynced) {
        limitedList = [[NSMutableArray alloc] initWithArray:nonEmptyConversations copyItems:YES];
    } else {
        [nonEmptyConversations sortUsingComparator:^NSComparisonResult(CMPChatConversation * obj1, CMPChatConversation * obj2) {
            return [obj1.updatedOn compare:obj2.updatedOn];
        }];
        for (int i = 0; i < _maxConversationsSynced; i++) {
            [limitedList addObject:nonEmptyConversations[i]];
        }
    }
    
    return nil;
}

- (NSDictionary<NSString *, CMPChatConversation *> *)dictionaryFromSavedConversations:(NSArray<CMPChatConversation *> *)conversations {
    NSMutableDictionary<NSString *, CMPChatConversation *> *dict = [NSMutableDictionary new];
    
    [conversations enumerateObjectsUsingBlock:^(CMPChatConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dict[obj.id] = obj;
    }];
    
    return dict;
}

- (void)handleNonLocalConversation:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    __weak typeof(self) weakSelf = self;
    [[weakSelf withClient].services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * result) {
        if (result.error) {
            completion([[CMPChatResult alloc] initWithComapiResult:result]);
        } else if (result.object) {
            [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object]] completion:^(BOOL success, NSError * _Nullable err) {
                completion([[CMPChatResult alloc] initWithError:err success:success]);
            }];
        }
    }];
}

- (void)handleParticipantsAddedForID:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    [_persistenceController getConversationForID:ID completion:^(CMPChatConversation * conversation, NSError * error) {
        if (!conversation) {
            [self handleNonLocalConversation:ID completion:^(CMPChatResult * result) {
                completion(result);
            }];
        } else {
            completion([[CMPChatResult alloc] initWithError:nil success:YES]);
        }
    }];
}

- (void)handleConversationCreated:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.error) {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    } else {
        [_persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object eTag:result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success eTag:result.eTag]);
        }];
    }
}

- (void)handleConversationDeleted:(NSString *)ID result:(CMPResult<NSNumber *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.code != kETagNotValid) {
        [_persistenceController deleteConversationForID:ID completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        [[weakSelf withClient].services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * _result) {
            if (_result.error) {
                completion([[CMPChatResult alloc] initWithError:result.error success:NO]);
            } else if (_result.object) {
                [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:_result.object eTag:_result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
                    completion([[CMPChatResult alloc] initWithError:error success:success]);
                }];
            }
        }];
    }
}

- (void)handleConversationUpdated:(CMPConversationUpdate *)update result:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error) {
        [_persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object eTag:result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else if (result.code == kETagNotValid) {
        __weak typeof(self) weakSelf = self;
        [[weakSelf withClient].services.messaging getConversationWithConversationID:update.id completion:^(CMPResult<CMPConversation *> * _result) {
            if (!_result.error && _result.object) {
                [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:_result.object eTag:_result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
                    completion([[CMPChatResult alloc] initWithError:error success:success eTag:_result.eTag]);
                }];
            } else {
                completion([[CMPChatResult alloc] initWithError:result.error success:result.object != nil]);
            }
        }];
    } else {
        completion([[CMPChatResult alloc] initWithError:result.error success:result.object != nil]);
    }
}





//
///**
// * Compares remote and local conversation lists.
// *
// * @param successful True if the service call was successful.
// * @param remote     Conversation list obtained from the server.
// * @param local      Conversation list obtained from local store.
// * @return Comparison object.
// */
//ConversationComparison compare(boolean successful, List<Conversation> remote, List<ChatConversationBase> local) {
//    return new ConversationComparison(successful, makeMapFromDownloadedConversations(remote), makeMapFromSavedConversations(local));
//}

- (CMPConversationComparator *)compare:(BOOL)success remote:(NSArray<CMPConversation *> *)remote local:(NSArray<CMPChatConversation *> *)local {
    // TODO: -
    return nil;
}

///**
// * Checks local conversation object if it need to be updated.
// *
// * @param remoteLastEventId Id of the last conversation event known by server.
// * @param conversation      Conversation state to check.
// * @return Comparison object.
// */
//ConversationComparison compare(Long remoteLastEventId, ChatConversationBase conversation) {
//    return new ConversationComparison(remoteLastEventId, conversation);
//}

- (CMPConversationComparator *)compare:(NSNumber *)latestRemoteEventID conversation:(CMPChatConversation *)conversation {
    // TODO: -
    return nil;
}


#pragma mark - Events

///**
// * Checks services for missing events in stored conversations.
// *
// * @param client                 Foundation client.
// * @param conversationComparison Describes differences in local and remote conversation list.
// * @return Observable returning unchanged argument to further processing.
// */
//private Observable<ConversationComparison> lookForMissingEvents(final RxComapiClient client, ConversationComparison conversationComparison) {
//
//    if (!conversationComparison.isSuccessful || conversationComparison.conversationsToUpdate.isEmpty()) {
//        return Observable.fromCallable(() -> conversationComparison);
//    }
//
//    return synchroniseEvents(client, conversationComparison.conversationsToUpdate, new ArrayList<>())
//    .map(result -> {
//        if (conversationComparison.isSuccessful && !result) {
//            conversationComparison.addSuccess(false);
//        }
//        return conversationComparison;
//    });
//}

- (void)lookForMissingEvents {
    // TODO: -
}

///**
// * Synchronise missing events for the list of locally stored conversations.
// *
// * @param client                Foundation client.
// * @param conversationsToUpdate List of conversations to query last events.
// * @param successes             List of partial successes.
// * @return Observable with the merged result of operations.
// */
//private Observable<Boolean> synchroniseEvents(final RxComapiClient client, @NonNull final List<ChatConversation> conversationsToUpdate, @NonNull final List<Boolean> successes) {
//
//    final List<ChatConversation> limited = limitNumberOfConversations(conversationsToUpdate);
//
//    if (limited.isEmpty()) {
//        return Observable.fromCallable(() -> true);
//    }
//
//    return Observable.from(limited)
//    .onBackpressureBuffer()
//    .flatMap(conversation -> persistenceController.getConversation(conversation.getConversationId()))
//    .flatMap(conversation -> {
//        if (conversation.getLastRemoteEventId() > conversation.getLastLocalEventId()) {
//            final long from = conversation.getLastLocalEventId() >= 0 ? conversation.getLastLocalEventId() : 0;
//            return queryEventsRecursively(client, conversation.getConversationId(), from, 0, successes).map(ComapiResult::isSuccessful);
//        } else {
//            return Observable.fromCallable((Callable<Object>) () -> true);
//        }
//    })
//    .flatMap(res -> Observable.from(successes).all(Boolean::booleanValue));
//}

- (void)synchronizeEvents:(NSArray<CMPChatConversation *> *)conversationsToUpdate completion:(void(^)(BOOL))completion {
    NSArray<CMPChatConversation *> *limited = [self limitNumberOfConversations:conversationsToUpdate];
    
    if (limited.count == 0) {
        completion(YES);
    }
    
    // TODO: -
}

- (void)queryEventsRecursively:(NSString *)conversationID lastEventID:(NSNumber *)lastEventID count:(NSNumber *)count completion:(void(^)(CMPResult<NSArray<CMPEvent *> *> *))completion {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging queryEventsWithConversationID:conversationID limit:_eventsPerQuery from:lastEventID.integerValue completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
        [weakSelf processEventsQuery:result completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
            if (result.object && result.object.count >= weakSelf.eventsPerQuery && count.integerValue < weakSelf.maxEventQueries) {
                [weakSelf queryEventsRecursively:conversationID lastEventID:@(lastEventID.integerValue + result.object.count) count:@(count.integerValue + 1) completion:completion];
            } else {
                completion(result);
            }
        }];
    }];
}

- (void)processEventsQuery:(CMPResult<NSArray<CMPEvent *> *> *)queryResult completion:(void(^)(CMPResult<NSArray<CMPEvent *> *> *))completion {
    __weak typeof(self) weakSelf = self;
    NSArray<CMPEvent *> *events = queryResult.object;
    if (events != nil && events.count > 0) {
        dispatch_group_t group = dispatch_group_create();
        
        [events enumerateObjectsUsingBlock:^(CMPEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            switch (obj.type) {
                case CMPEventTypeConversationMessageRead: {
                    dispatch_group_enter(group);
                    CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithReadEvent:(CMPConversationMessageEventRead *)obj];
                    [weakSelf.persistenceController upsertMessageStatus:status completion:^(BOOL success, NSError * _Nullable error) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed read event, success: %d, error: %@", success, error], nil);
                        dispatch_group_leave(group);
                    }];
                    
                    break;
                }
                case CMPEventTypeConversationMessageSent: {
                    dispatch_group_enter(group);
                    CMPChatMessage *msg = [[CMPChatMessage alloc] initWithSentEvent:(CMPConversationMessageEventSent *) obj];
                    [weakSelf.persistenceController updateStoreWithNewMessage:msg completion:^(BOOL success, NSError * _Nullable error) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed sent event, success: %d, error: %@", success, error], nil);
                        dispatch_group_leave(group);
                    }];
                    
                    break;
                }
                case CMPEventTypeConversationMessageDelivered: {
                    dispatch_group_enter(group);
                    CMPChatMessageStatus *status = [[CMPChatMessageStatus alloc] initWithDeliveredEvent:(CMPConversationMessageEventDelivered *)obj];
                    [weakSelf.persistenceController upsertMessageStatus:status completion:^(BOOL success, NSError * _Nullable error) {
                        logWithLevel(CMPLogLevelInfo, [NSString stringWithFormat:@"Processed delivered event, success: %d, error: %@", success, error], nil);
                        dispatch_group_leave(group);
                    }];
                    break;
                }
                default:
                    break;
            }
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completion(queryResult);
        });
    } else {
        logWithLevel(CMPLogLevelWarning, @"Events array empty or nil, returning...");
        completion(queryResult);
    }
}

- (void)queryMissingEvents:(NSString *)ID from:(NSInteger)from limit:(NSInteger)limit {
    __weak typeof(self) weakSelf = self;
    [[self withClient].services.messaging queryEventsWithConversationID:ID limit:limit from:from completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
        [weakSelf processEventsQuery:result completion:^(CMPResult<NSArray<CMPEvent *> *> * result) {
            
        }];
    }];
}

@end
