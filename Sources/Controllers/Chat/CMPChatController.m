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
#import "CMPChatResult.h"
#import "CMPRetryManager.h"

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

- (BOOL)isConfigured;

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

- (BOOL)isConfigured {
    return _client != nil;
}

- (void)handleSocketConnected {
    _socketWasDisconnected = NO;
    if ([_callLimiter checkAndIncrease]) {
        
    }
}

- (void)handleSocketDisconnectedWithError:(NSError *)error {
    _socketWasDisconnected = YES;
}

- (nullable NSString *)getProfileID {
    return _client != nil ? [_client getProfileID] : nil;
}

- (void)markDeliveredForConversationID:(NSString *)ID messageIDs:(NSArray<NSString *> *)IDs completion:(void(^)(CMPChatResult *))completion {
    if ([self isConfigured]) {
        __weak typeof(self) weakSelf = self;
        [CMPRetryManager retryBlock:^(void (^successBlock)(BOOL)) {
            [weakSelf.client.services.messaging updateStatusForMessagesWithIDs:IDs status:CMPMessageDeliveryStatusDelivered conversationID:ID timestamp:[NSDate date] completion:^(CMPResult<NSNumber *> * result) {
                BOOL success = !result.error && result.object;
                successBlock(success);
                if (success) {
                    completion([[CMPChatResult alloc] initWithComapiResult:result]);
                }
            }];
        } attempts:3 interval:3];
    }
}

- (void)handleNonLocalConversationForID:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    if ([self isConfigured]) {
        __weak typeof(self) weakSelf = self;
        [self.client.services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * result) {
            if (result.error) {
                completion([[CMPChatResult alloc] initWithComapiResult:result]);
            } else if (result.object) {
                [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object]] completion:^(BOOL success, NSError * _Nullable err) {
                    completion([[CMPChatResult alloc] initWithError:err success:success]);
                }];
            }
        }];
    }
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
        [self markDeliveredForConversationID:message.context.conversationID messageIDs:ids completion:^(CMPChatResult * result) {
            markDeliveredResult = result;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(updateStoreSuccess && markDeliveredResult.isSuccessful, markDeliveredResult.error);
    });
}

- (void)handleParticipantsAddedForID:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
    [_persistenceController getConversationForID:ID completion:^(CMPChatConversation * conversation, NSError * error) {
        if (!conversation) {
            [self handleNonLocalConversationForID:ID completion:^(CMPChatResult * result) {
                completion(result);
            }];
        } else {
            completion([[CMPChatResult alloc] initWithError:nil success:YES]);
        }
    }];
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

- (void)handleMessageError:()err{}

- (void)getPreviousMessagesForID:(NSString *)ID completion:(void(^)(CMPChatResult *))completion {
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
            if ([self isConfigured]) {
                [self.client.services.messaging getMessagesWithConversationID:ID from:queryFrom.integerValue completion:^(CMPResult<CMPGetMessagesResult *> * result) {
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

- (void)handleConversationDeletedForID:(NSString *)ID result:(CMPResult<NSNumber *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.code != kETagNotValid) {
        [_persistenceController deleteConversationForID:ID completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else {
        if ([self isConfigured]) {
            __weak typeof(self) weakSelf = self;
            [_client.services.messaging getConversationWithConversationID:ID completion:^(CMPResult<CMPConversation *> * _result) {
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
}

///**
// * Handles conversation delete service response.
// *
// * @param conversationId Unique identifier of an conversation.
// * @param result         Service call response.
// * @return Observable emitting result of operations.
// */
//Observable<ChatResult> handleConversationDeleted(String conversationId, ComapiResult<Void> result) {
//    if (result.getCode() != ETAG_NOT_VALID) {
//        return persistenceController.deleteConversation(conversationId).map(success -> adapter.adaptResult(result, success));
//    } else {
//        return checkState().flatMap(client -> client.service().messaging().getConversation(conversationId)
//                                    .flatMap(newResult -> {
//            if (newResult.isSuccessful()) {
//                return persistenceController.upsertConversation(ChatConversation.builder().populate(newResult.getResult(), newResult.getETag()).build())
//                .flatMap(success -> Observable.fromCallable(() -> new ChatResult(false, success ? new ChatResult.Error(ETAG_NOT_VALID, "Conversation updated, try delete again.", "Conversation "+conversationId+" updated in response to  wrong eTag error when deleting.") : new ChatResult.Error(0, "Error updating custom store.", null))));
//            } else {
//                return Observable.fromCallable(() -> adapter.adaptResult(newResult));
//            }
//        }));
//    }
//}

- (void)handleConversationUpdated:(CMPConversationUpdate *)update result:(CMPResult<CMPConversation *> *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error) {
        [_persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:result.object eTag:result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else if (result.code == kETagNotValid) {
        if ([self isConfigured]) {
            __weak typeof(self) weakSelf = self;
            [_client.services.messaging getConversationWithConversationID:update.id completion:^(CMPResult<CMPConversation *> * _result) {
                if (!_result.error && _result.object) {
                    [weakSelf.persistenceController upsertConversations:@[[[CMPChatConversation alloc] initWithConversation:_result.object eTag:_result.eTag]] completion:^(BOOL success, NSError * _Nullable error) {
                        completion([[CMPChatResult alloc] initWithError:error success:success eTag:_result.eTag]);
                    }];
                } else {
                    completion([[CMPChatResult alloc] initWithError:result.error success:result.object]);
                }
            }];
        }
    } else {
        completion([[CMPChatResult alloc] initWithError:result.error success:result.object]);
    }
}

///**
// * Handles conversation update service response.
// *
// * @param request Service API request object.
// * @param result  Service call response.
// * @return Observable emitting result of operations.
// */
//Observable<ChatResult> handleConversationUpdated(ConversationUpdate request, ComapiResult<ConversationDetails> result) {
//
//    if (result.isSuccessful()) {
//
//        return persistenceController.upsertConversation(ChatConversation.builder().populate(result.getResult(), result.getETag()).build()).map(success -> adapter.adaptResult(result, success));
//    }
//    if (result.getCode() == ETAG_NOT_VALID) {
//
//        return checkState().flatMap(client -> client.service().messaging().getConversation(request.getId())
//                                    .flatMap(newResult -> {
//            if (newResult.isSuccessful()) {
//
//                return persistenceController.upsertConversation(ChatConversation.builder().populate(newResult.getResult(), newResult.getETag()).build())
//                .flatMap(success -> Observable.fromCallable(() -> new ChatResult(false, success ? new ChatResult.Error(ETAG_NOT_VALID, "Conversation updated, try delete again.", "Conversation "+request.getId()+" updated in response to  wrong eTag error when updating."): new ChatResult.Error(1500, "Error updating custom store.", null))));
//            } else {
//                return Observable.fromCallable(() -> adapter.adaptResult(newResult));
//            }
//        }));
//    } else {
//
//        return Observable.fromCallable(() -> adapter.adaptResult(result));
//    }
//}

//private static final int ETAG_NOT_VALID = 412;
//
//private final Integer messagesPerQuery;
//
//private final Integer eventsPerQuery;
//
//private final AttachmentController attCon;
//
//private int maxEventQueries;
//
//private int maxConversationsSynced;
//
//private final WeakReference<RxComapiClient> clientReference;
//
//private final ModelAdapter adapter;
//
//private final PersistenceController persistenceController;
//
//private final ObservableExecutor obsExec;
//
//private final Logger log;
//
//private NoConversationListener noConversationListener;
//
//private OrphanedEventsToRemoveListener orphanedEventsToRemoveListener;
//
//interface NoConversationListener {
//    void getConversation(String conversationId);
//}
//
//interface OrphanedEventsToRemoveListener {
//    void remove(String[] ids);
//}
//
//private final AtomicBoolean isSynchronising;
//
//private final AtomicBoolean socketWasDisconnected;
//private final CallLimiter syncCallsLimiter;

//ChatController(final RxComapiClient client, final PersistenceController persistenceController, final AttachmentController attachmentController, InternalConfig internal, final ObservableExecutor obsExec, final ModelAdapter adapter, final Logger log) {
//    this.isSynchronising = new AtomicBoolean(false);
//    this.clientReference = new WeakReference<>(client);
//    this.adapter = adapter;
//    this.log = log;
//    this.persistenceController = persistenceController;
//    this.obsExec = obsExec;
//    this.noConversationListener = conversationId -> obsExec.execute(handleNoLocalConversation(conversationId));
//    this.orphanedEventsToRemoveListener = ids -> obsExec.execute(persistenceController.deleteOrphanedEvents(ids));
//    this.attCon = attachmentController;
//
//    messagesPerQuery = internal.getMaxMessagesPerPage();
//    eventsPerQuery = internal.getMaxEventsPerQuery();
//    maxEventQueries = internal.getMaxEventQueries();
//    maxConversationsSynced = internal.getMaxConversationsSynced();
//
//    this.socketWasDisconnected = new AtomicBoolean(false);
//
//}
//
//void handleSocketConnected() {
//    System.out.println("handleSocketConnected");
//    if (socketWasDisconnected.compareAndSet(true, false)) {
//        if (syncCallsLimiter.checkAndIncrease()) {
//            System.out.println("auto synchroniseStore");
//            obsExec.execute(synchroniseStore());
//        }
//    }
//}
//
//void handleSocketDisconnected() {
//    System.out.println("handleSocketConnected");
//    socketWasDisconnected.compareAndSet(false, true);
//}
//
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
//}
//

//

//
///**
// * Checks if controller state is correct.
// *
// * @return Foundation client instance.
// */
//Observable<RxComapiClient> checkState() {
//
//    final RxComapiClient client = clientReference.get();
//    if (client == null) {
//        return Observable.error(new ComapiException("No client instance available in controller."));
//    } else {
//        return Observable.fromCallable(() -> client);
//    }
//}
//

//
///**
// * Mark messages in a conversations as delivered.
// *
// * @param conversationId Conversation unique id.
// * @param ids            Ids of messages in a single conversation to be marked as delivered.
// */

//

//
///**
// * Gets profile id from Foundation for the active user.
// *
// * @return Active user profile id.
// */
//String getProfileId() {
//    final RxComapiClient client = clientReference.get();
//    return client != null ? client.getSession().getProfileId() : null;
//}
//
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
//

//

- (void)handleMessageStatusToUpdateForID:(NSString *)ID statusUpdates:(NSArray<CMPMessageStatusUpdate *> *)statusUpdates result:(CMPResult *)result completion:(void(^)(CMPChatResult *))completion {
    if (result.object && !result.error && statusUpdates.count > 0) {
        [_persistenceController upsertMessageStatusesForConversationID:ID profileID:[self getProfileID] statuses:statusUpdates completion:^(BOOL success, NSError * _Nullable error) {
            completion([[CMPChatResult alloc] initWithError:error success:success]);
        }];
    } else {
        completion([[CMPChatResult alloc] initWithComapiResult:result]);
    }
}

//
///**
// * Handles message status update service response.
// *
// * @param msgStatusList List of message status updates to process.
// * @param result        Service call response.
// * @return Observable emitting result of operations.
// */
//Observable<ChatResult> handleMessageStatusToUpdate(String conversationId, List<MessageStatusUpdate> msgStatusList, ComapiResult<Void> result) {
//    if (result.isSuccessful() && msgStatusList != null && !msgStatusList.isEmpty()) {
//        return persistenceController.upsertMessageStatuses(conversationId, getProfileId(), msgStatusList).map(success -> adapter.adaptResult(result, success));
//    } else {
//        return Observable.fromCallable(() -> adapter.adaptResult(result));
//    }
//}

- (void)upsertTempMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
    [_persistenceController updateStoreWithNewMessage:message completion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            logWithLevel(CMPLogLevelError, @"Error saving temp message: %@", error.localizedDescription, nil);
        }
        completion(success);
    }];
}
//
///**
// * Insert temporary message to the store for the ui to be responsive.
// *
// * @param message Message to be send.
// * @return Observable emitting result of operations.
// */
//private Observable<Boolean> upsertTempMessage(ChatMessage message) {
//    return persistenceController.updateStoreWithNewMessage(message, noConversationListener)
//    .doOnError(t -> log.e("Error saving temp message " + t.getLocalizedMessage()))
//    .onErrorReturn(t -> false);
//}
//

- (void)updateStoreWithSentMessage:(CMPChatMessage *)message completion:(void(^)(BOOL))completion {
//    [_persistenceController updateStoreWithNewMessage:message completion:^(BOOL success, NSError * _Nullable error) {
//        if (error) {
//            logWithLevel(CMPLogLevelError, @"Error saving temp message: %@", error.localizedDescription, nil);
//        }
//        completion(success);
//    }];
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
//

- (void)synchronizeConversationsWithCompletion:(void(^)(CMPChatResult *))completion {
    if ([self isConfigured]) {
        __weak typeof(self) weakSelf = self;
        [_client.services.messaging getConversationsWithProfileID:[self getProfileID] isPublic:NO completion:^(CMPResult<NSArray<CMPConversation *> *> * result) {
            [weakSelf.persistenceController getAllConversationsWithCompletion:^(NSArray<CMPChatConversation *> * _Nullable conversations, NSError * _Nullable error) {
                
            }];
        }];
    }
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
//
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
//
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
//
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
//
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
//
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
//
///**
// * Synchronise missing events for particular conversation.
// *
// * @param client         Foundation client.
// * @param conversationId Unique ID of a conversation.
// * @param lastEventId    Last known event id - query should start form it.
// * @param count          Number of queries already made.
// * @param successes      list of query & processing results in recursive call.
// * @return Observable with the merged result of operations.
// */
//private Observable<ComapiResult<ConversationEventsResponse>> queryEventsRecursively(final RxComapiClient client, final String conversationId, final long lastEventId, final int count, final List<Boolean> successes) {
//
//    return client.service().messaging().queryConversationEvents(conversationId, lastEventId, eventsPerQuery)
//    .flatMap(result -> processEventsQueryResponse(result, successes))
//    .flatMap(result -> {
//        if (result.getResult() != null && result.getResult().getEventsInOrder().size() >= eventsPerQuery && count < maxEventQueries) {
//            return queryEventsRecursively(client, conversationId, lastEventId + result.getResult().getEventsInOrder().size(), count + 1, successes);
//        } else {
//            return Observable.just(result);
//        }
//    });
//}
//
///**
// * Process the event query response. Calls appropraiate persistance controller methods for received events.
// *
// * @param result    Event query response.
// * @param successes List of successes in recursive query.
// * @return Observable with same result object for further processing.
// */
//private Observable<ComapiResult<ConversationEventsResponse>> processEventsQueryResponse(ComapiResult<ConversationEventsResponse> result, final List<Boolean> successes) {
//
//    ConversationEventsResponse response = result.getResult();
//    successes.add(result.isSuccessful());
//    if (response != null && response.getEventsInOrder().size() > 0) {
//
//        Collection<Event> events = response.getEventsInOrder();
//
//        List<Observable<Boolean>> list = new ArrayList<>();
//
//        for (Event event : events) {
//
//            if (event instanceof MessageSentEvent) {
//                MessageSentEvent messageEvent = (MessageSentEvent) event;
//                list.add(persistenceController.updateStoreWithNewMessage(ChatMessage.builder().populate(messageEvent).build(), noConversationListener));
//            } else if (event instanceof MessageDeliveredEvent) {
//                list.add(persistenceController.upsertMessageStatus(ChatMessageStatus.builder().populate((MessageDeliveredEvent) event).build()));
//            } else if (event instanceof MessageReadEvent) {
//                list.add(persistenceController.upsertMessageStatus(ChatMessageStatus.builder().populate((MessageReadEvent) event).build()));
//            }
//        }
//
//        return Observable.from(list)
//        .flatMap(task -> task)
//        .doOnNext(successes::add)
//        .toList()
//        .map(results -> result);
//    }
//
//    return Observable.fromCallable(() -> result);
//}
//
///**
// * Limits number of conversations to check and synchronise. Emty conversations wont be synchronised. The synchronisation will take place for twenty conversations updated most recently.
// *
// * @param conversations List of conversations to be limited.
// * @return Limited list of conversations to update.
// */
//private List<ChatConversation> limitNumberOfConversations(List<ChatConversation> conversations) {
//
//    List<ChatConversation> noEmptyConversations = new ArrayList<>();
//    for (ChatConversation c : conversations) {
//        if (c.getLastRemoteEventId() != null && c.getLastRemoteEventId() >= 0) {
//            noEmptyConversations.add(c);
//        }
//    }
//
//    List<ChatConversation> limitedList;
//
//    if (noEmptyConversations.size() <= maxConversationsSynced) {
//        limitedList = noEmptyConversations;
//    } else {
//        SortedMap<Long, ChatConversation> sorted = new TreeMap<>();
//        for (ChatConversation conversation : noEmptyConversations) {
//            sorted.put(conversation.getUpdatedOn(), conversation);
//        }
//        limitedList = new ArrayList<>();
//        Object[] array = sorted.values().toArray();
//        for (int i = 0; i < maxConversationsSynced; i++) {
//            limitedList.add((ChatConversation) array[i]);
//        }
//    }
//
//    return limitedList;
//}
//
///**
// * Handle incomming message. Replace temporary message with received one and mark as delivered.
// *
// * @param message Message to save and mark delivered.
// * @return Observable with a result.
// */
//public Observable<Boolean> handleMessage(final ChatMessage message) {
//
//    String sender = message.getSentBy();
//
//    Observable<Boolean> replaceMessages = persistenceController.updateStoreWithNewMessage(message, noConversationListener);
//
//    if (!TextUtils.isEmpty(sender) && !sender.equals(getProfileId())) {
//
//        final Set<String> ids = new HashSet<>();
//        ids.add(message.getMessageId());
//
//        return Observable.zip(replaceMessages, markDelivered(message.getConversationId(), ids), (saved, result) -> saved && result.isSuccessful());
//
//    } else {
//
//        return replaceMessages;
//    }
//}
//
///**
// * Query missing events as {@link com.comapi.chat.internal.MissingEventsTracker} reported.
// *
// * @param conversationId Unique id of a conversation.
// * @param from           Conversation event id to start from.
// * @param limit          Limit of events in a query.
// */
//void queryMissingEvents(String conversationId, long from, int limit) {
//    obsExec.execute(checkState().flatMap(client -> client.service().messaging().queryConversationEvents(conversationId, from, limit))
//                    .flatMap((result) -> processEventsQueryResponse(result, new ArrayList<>())));
//}
//
///**
// * Creates map of conversations based on conversationId for internal purpose.
// *
// * @param list List of conversations.
// * @return Map of conversations.
// */
//private Map<String, ChatConversationBase> makeMapFromSavedConversations(List<ChatConversationBase> list) {
//
//    Map<String, ChatConversationBase> map = new HashMap<>();
//
//    if (list != null && !list.isEmpty()) {
//        for (ChatConversationBase details : list) {
//            map.put(details.getConversationId(), details);
//        }
//    }
//
//    return map;
//}
//
///**
// * Creates map of conversations based on conversationId for internal purpose.
// *
// * @param list List of conversations.
// * @return Map of conversations.
// */
//private Map<String, Conversation> makeMapFromDownloadedConversations(List<Conversation> list) {
//
//    Map<String, Conversation> map = new HashMap<>();
//
//    if (list != null && !list.isEmpty()) {
//        for (Conversation details : list) {
//            map.put(details.getId(), details);
//        }
//    }
//
//    return map;
//}
//


@end
