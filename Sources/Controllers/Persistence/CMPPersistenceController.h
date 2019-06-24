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

#import "CMPChatStoreFactory.h"
#import "CMPStoreResult.h"
#import "CMPModelAdapter.h"
#import "CMPCoreDataManager.h"
#import "CMPChatConversation.h"

#import <CMPComapiFoundation/CMPGetMessagesResult.h>
#import <CMPComapiFoundation/CMPMessageStatusUpdate.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PersistenceController)
@interface CMPPersistenceController : NSObject

@property (nonatomic, strong, readonly) CMPChatStoreFactory *factory;
@property (nonatomic, strong, readonly) CMPModelAdapter *adapter;
@property (nonatomic, strong, readonly) CMPCoreDataManager *manager;

+ (void)initialiseWithFactory:(id<CMPChatStoreFactoryBuilderProvider>)factory adapter:(CMPModelAdapter *)adapter coreDataManager:(CMPCoreDataManager *)manager completion:(void (^ _Nullable)(CMPPersistenceController * _Nullable, NSError * _Nullable))completion;

- (void)getConversation:(NSString *)conversationID completion:(void(^)(CMPStoreResult<CMPChatConversation *> *))completion;
- (void)getAllConversations:(void(^)(CMPStoreResult<NSArray<CMPChatConversation *> *> *))completion;
- (void)upsertConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;
- (void)updateConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;
- (void)deleteConversation:(NSString *)ID completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;
- (void)deleteConversations:(NSArray<CMPChatConversation *> *)conversations completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;

- (void)processOrphanedEvents:(CMPGetMessagesResult *)eventsResult completion:(void(^)(NSError * _Nullable))completion;
- (void)deleteOrphanedEvents:(NSArray<NSString *> *)IDs completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;

- (void)processMessagesResult:(NSString *)ID result:(CMPGetMessagesResult *)result completion:(void(^)(CMPStoreResult<CMPGetMessagesResult *> *))completion;

- (void)updateStoreWithNewMessage:(CMPChatMessage *)message completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;
- (void)updateStoreWithSentError:(NSString *)conversationID tempID:(NSString *)tempID profileID:(NSString *)profileID completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;

- (void)upsertMessageStatuses:(NSString *)conversationID profileID:(NSString *)profileID statuses:(NSArray<CMPMessageStatusUpdate *> *)statuses completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;
- (void)upsertMessageStatus:(CMPChatMessageStatus *)status completion:(void(^)(CMPStoreResult<NSNumber *> *))completion;

-(void)clear:(void(^)(CMPStoreResult<NSNumber *> *))completion;

@end

NS_ASSUME_NONNULL_END
