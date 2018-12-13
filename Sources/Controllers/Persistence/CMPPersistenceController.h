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

#import "CMPStoreFactory.h"
#import "CMPModelAdapter.h"
#import "CMPCoreDataManager.h"
#import "CMPChatConversation.h"

#import <CMPComapiFoundation/CMPGetMessagesResult.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPPersistenceController : NSObject

@property (nonatomic, strong, readonly) CMPStoreFactory *factory;
@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;
@property (nonatomic, strong, readonly) CMPCoreDataManager *manager;

- (instancetype)initWithFactory:(CMPStoreFactory *)factory adapter:(CMPModelAdapter *)adapter coreDataManager:(CMPCoreDataManager *)manager;

- (void)getConversationForID:(NSString *)conversationID completion:(void(^)(CMPChatConversationBase *))completion;
- (void)processOrphanedEvents:(CMPGetMessagesResult *)eventsResult completion:(void(^)(NSError * _Nullable))completion;
//Observable<ComapiResult<MessagesQueryResponse>> processOrphanedEvents(ComapiResult<MessagesQueryResponse> result, final ChatController.OrphanedEventsToRemoveListener removeListener) {
//
//    if (result.isSuccessful() && result.getResult() != null) {
//
//        final MessagesQueryResponse response = result.getResult();
//
//        final List<MessageReceived> messages = response.getMessages();
//        final String[] ids = new String[messages.size()];
//
//        if (!messages.isEmpty()) {
//            for (int i = 0; i < messages.size(); i++) {
//                ids[i] = messages.get(i).getMessageId();
//            }
//        }
//
//        return db.save(response.getOrphanedEvents())
//        .flatMap(count -> db.queryOrphanedEvents(ids))
//        .flatMap(toDelete -> Observable.create(emitter ->
//                                               storeFactory.execute(new StoreTransaction<ChatStore>() {
//
//            @Override
//            protected void execute(ChatStore store) {
//
//                if (!toDelete.isEmpty()) {
//
//                    storeFactory.execute(new StoreTransaction<ChatStore>() {
//                        @Override
//                        protected void execute(ChatStore store) {
//
//                            store.beginTransaction();
//
//                            List<ChatMessageStatus> statuses = modelAdapter.adaptEvents(toDelete);
//
//                            if (!statuses.isEmpty()) {
//                                for (ChatMessageStatus status : statuses) {
//                                    store.update(status);
//                                }
//                            }
//
//                            String[] ids = new String[toDelete.size()];
//                            for (int i = 0; i < toDelete.size(); i++) {
//                                ids[i] = toDelete.get(i).id();
//                            }
//                            removeListener.remove(ids);
//
//                            store.endTransaction();
//
//                            emitter.onNext(result);
//                            emitter.onCompleted();
//                        }
//                    });
//                } else {
//                    emitter.onNext(result);
//                    emitter.onCompleted();
//                }
//            }
//        }), Emitter.BackpressureMode.BUFFER));
//    } else {
//        return Observable.fromCallable(() -> result);
//    }
//}
@end

NS_ASSUME_NONNULL_END
