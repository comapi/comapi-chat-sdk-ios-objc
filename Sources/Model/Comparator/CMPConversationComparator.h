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

#import "CMPChatConversation.h"

#import <CMPComapiFoundation/CMPConversation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CMPConversationComparator : NSObject

@property (nonatomic) BOOL remoteCallSuccessful;
@property (nonatomic) BOOL isSuccessful;

@property (nonatomic, strong) NSArray<CMPChatConversation *> *conversationsToAdd;
@property (nonatomic, strong) NSArray<CMPChatConversation *> *conversationsToDelete;
@property (nonatomic, strong) NSArray<CMPChatConversation *> *conversationsToUpdate;

- (instancetype)initWithDownloadedList:(NSDictionary<NSString *, CMPConversation *> *)downloadedList savedList:(NSDictionary<NSString *, CMPChatConversation *> *)savedList isSuccessful:(BOOL)isSuccessful;

@end

NS_ASSUME_NONNULL_END


//class ConversationComparison {
//
//    boolean remoteCallSuccessful = true;
//    boolean isSuccessful = false;
//
//    List<ChatConversation> conversationsToAdd;
//    List<ChatConversationBase> conversationsToDelete;
//    List<ChatConversation> conversationsToUpdate;
//
//    /**
//     * Creates remote and local conversation list comparison.
//     *
//     * @param successful     Was remote service call successful.
//     * @param downloadedList Remote list.
//     * @param savedList      Local list.
//     */
//    ConversationComparison(boolean successful, Map<String, Conversation> downloadedList, Map<String, ChatConversationBase> savedList) {
//
//        remoteCallSuccessful = successful;
//        conversationsToDelete = new ArrayList<>();
//        conversationsToUpdate = new ArrayList<>();
//        conversationsToAdd = new ArrayList<>();
//
//        Map<String, ChatConversationBase> savedListProcessed = new HashMap<>(savedList);
//
//        for (String key : downloadedList.keySet()) {
//            if (savedListProcessed.containsKey(key)) {
//
//                ChatConversationBase saved = savedListProcessed.get(key);
//                if (saved.getLastLocalEventId() != -1L) {
//                    conversationsToUpdate.add(ChatConversation.builder()
//                                              .populate(downloadedList.get(key))
//                                              .setFirstLocalEventId(saved.getFirstLocalEventId())
//                                              .setLastLocalEventId(saved.getLastLocalEventId())
//                                              .build());
//                }
//            } else {
//                conversationsToAdd.add(ChatConversation.builder().populate(downloadedList.get(key)).build());
//            }
//
//            savedListProcessed.remove(key);
//        }
//
//        if (!savedListProcessed.isEmpty()) {
//            conversationsToDelete.addAll(savedListProcessed.values());
//        }
//    }
//
//    /**
//     * Checks local conversation if it needs to be updated and creates comaprison object.
//     *
//     * @param remoteLastEventId Last event id in a conversation known by he server.
//     * @param conversation      Conversation object to check.
//     */
//    public ConversationComparison(Long remoteLastEventId, ChatConversationBase conversation) {
//
//        conversationsToDelete = new ArrayList<>();
//        conversationsToUpdate = new ArrayList<>();
//        conversationsToAdd = new ArrayList<>();
//
//        if (conversation != null && remoteLastEventId != null) {
//            if (conversation.getLastRemoteEventId() != null && conversation.getLastRemoteEventId() != -1L && remoteLastEventId > conversation.getLastRemoteEventId()) {
//                conversationsToUpdate.add(ChatConversation.builder().populate(conversation).setLastRemoteEventId(remoteLastEventId).build());
//            }
//        }
//
//        if (remoteLastEventId == null || remoteLastEventId == -1L) {
//            remoteCallSuccessful = false;
//        }
//    }
//
//    /**
//     * Set if processing of conversations was successful.
//     *
//     * @param isSuccessful TRue if processing of conversations was successful.
//     */
//    void addSuccess(boolean isSuccessful) {
//        this.isSuccessful = isSuccessful && remoteCallSuccessful;
//    }
//}
//}
