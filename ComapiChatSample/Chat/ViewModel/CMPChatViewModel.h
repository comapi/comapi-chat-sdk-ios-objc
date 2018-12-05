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

@import CMPComapiChat;
@import UIKit;

#import "CMPPhotoCropViewController.h"
#import "CMPImageDownloader.h"
#import "CMPStore.h"
#import "Message.h"
#import "MessageContext.h"
#import "MessageStatus.h"
#import "MessageParticipant.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatViewModel : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) CMPStore *store;
@property (nonatomic, strong) CMPComapiChatClient *client;
@property (nonatomic, strong) CMPChatConversation *conversation;
@property (nonatomic, strong) CMPImageDownloader *downloader;
@property (nonatomic, strong) NSFetchedResultsController<Message *> *fetchController;

@property (atomic, strong) NSMutableArray<UIImage *> *imageAttachments;
@property (atomic, strong) NSMutableArray<CMPChatParticipant *> *participants;

@property (nonatomic, copy) void(^shouldReloadAttachments)(void);
@property (nonatomic, copy) void(^shouldReloadDataAtIndex)(BOOL, NSFetchedResultsChangeType, NSInteger);
@property (nonatomic, copy) void(^shouldReloadData)(BOOL);
@property (nonatomic, copy) void(^didTakeNewPhoto)(UIImage *);

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store conversation:(CMPChatConversation *)conversation;

- (void)getParticipantsWithCompletion:(void(^)(NSArray<CMPChatParticipant *> * _Nullable, NSError * _Nullable))completion;
- (void)getPreviousMessages:(void (^)(NSError * _Nullable))completion;
- (void)synchroniseConversation:(void (^)(NSError * _Nullable))completion;
- (void)sendMessage:(NSString *)message completion:(void(^)(NSError * _Nullable))completion;
- (void)markReadWithCompletion:(void (^)(NSError * _Nullable))completion;
- (void)showPhotoSourceControllerWithPresenter:(void (^)(UIViewController *))presenter alertPresenter:(void (^)(UIViewController *))alertPresenter pickerPresenter:(void (^)(UIViewController *))pickerPresenter;
- (void)showPhotoCropControllerWithImage:(UIImage *)image presenter:(void(^)(UIViewController *))presenter;

@end

NS_ASSUME_NONNULL_END
