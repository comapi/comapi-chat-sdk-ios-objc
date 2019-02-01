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

#import "CMPChatViewModel.h"
#import "CMPEventParser.h"
#import "CMPConversationMessageEvents.h"
#import "CMPPhotoVideoManager.h"
#import "UIImage+CMPUtilities.h"

@implementation CMPChatViewModel

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store conversation:(CMPChatConversation *)conversation {
    self = [super init];
    
    if (self) {
        self.client = client;
        self.store = store;
        self.store.messageDelegate = self;
        self.conversation = conversation;
        self.messages = [NSMutableArray new];
        self.downloader = [[CMPImageDownloader alloc] init];
    }
    
    return self;
}

- (void)getPreviousMessages:(void (^)(NSError * _Nullable))completion {
    [self.client.services.messaging getPreviousMessages:self.conversation.id completion:^(CMPChatResult * result) {
        completion(result.error);
    }];
}

- (void)synchroniseConversation:(void (^)(NSError * _Nullable))completion {
    [self.client.services.messaging synchroniseConversation:self.conversation.id completion:^(CMPChatResult * result) {
        completion(result.error);
    }];
}

- (void)getMessagesWithCompletion:(void (^)(NSArray<CMPChatMessage *> * _Nullable, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;

    NSMutableArray<CMPChatMessage *> *messages = [NSMutableArray arrayWithArray:[self.store getMessages:weakSelf.conversation.id]];
    weakSelf.messages = messages != nil ? messages : [NSMutableArray new];
    completion(weakSelf.messages, nil);
}

- (void)sendMessage:(NSString *)message attachments:(NSArray<CMPChatAttachment *> *)attachments completion:(void (^)(NSError * _Nullable))completion {
    NSDictionary<NSString *, id> *metadata = @{@"my_message_id" : [[NSUUID UUID] UUIDString]};
    CMPMessagePart *textPart = [[CMPMessagePart alloc] initWithName:@"" type:@"text/plain" url:nil data:message size:@(message.length)];
    CMPSendableMessage *newMessage = [[CMPSendableMessage alloc] initWithMetadata:metadata parts:@[textPart] alert:nil];
    [self.client.services.messaging sendMessage:_conversation.id message:newMessage attachments:attachments completion:^(CMPChatResult * result) {
        completion(result.error);
    }];
}


//- (void)sendTextMessage:(NSString *)message completion:(void (^)(NSError * _Nullable))completion {
//    NSDictionary<NSString *, id> *metadata = @{@"myMessageID" : @"123"};
//    CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"" type:@"text/plain" url:nil data:message size:[NSNumber numberWithUnsignedLong:sizeof(message.UTF8String)]];
//    CMPSendableMessage *sendableMessage = [[CMPSendableMessage alloc] initWithMetadata:metadata parts:@[part] alert:nil];
//
//    [self.client.services.messaging sendMessage:sendableMessage toConversationWithID:self.conversation.id completion:^(CMPResult<CMPSendMessagesResult *> *result) {
//        if (result.error) {
//            completion(result.error);
//        } else {
//            completion(nil);
//        }
//    }];
//}

//- (void)uploadContent:(CMPContentData *)content completion:(void (^)(CMPContentUploadResult * _Nullable, NSError * _Nullable))completion {
//    [self.client.services.messaging uploadContent:content folder:nil completion:^(CMPResult<CMPContentUploadResult *> *result) {
//        if (result.error) {
//            completion(nil, result.error);
//        } else {
//            completion(result.object, nil);
//        }
//    }];
//}
//


//- (void)sendImageWithUploadResult:(CMPContentUploadResult *)result completion:(void (^)(NSError * _Nullable))completion {
//    NSDictionary<NSString *, id> *metadata = @{@"myMessageID" : @"123"};
//    CMPMessagePart *part = [[CMPMessagePart alloc] initWithName:@"image" type:result.type url:result.url data:nil size:nil];
//    CMPSendableMessage *message = [[CMPSendableMessage alloc] initWithMetadata:metadata parts:@[part] alert:nil];
//
//    [self.client.services.messaging sendMessage:message toConversationWithID:self.conversation.id completion:^(CMPResult<CMPSendMessagesResult *> *result) {
//        if (result.error) {
//            completion(result.error);
//        } else {
//            completion(nil);
//        }
//    }];
//}

- (void)showPhotoSourceControllerWithPresenter:(void (^)(UIViewController * _Nonnull))presenter alertPresenter:(void (^)(UIViewController * _Nonnull))alertPresenter pickerPresenter:(void (^)(UIViewController * _Nonnull))pickerPresenter {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([CMPPhotoVideoManager.shared isSourceAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [CMPPhotoVideoManager.shared requestPhotoLibraryAccessWithCompletion:^(BOOL success) {
                if (success) {
                    UIImagePickerController *vc = [CMPPhotoVideoManager.shared imagePickerControllerForType:UIImagePickerControllerSourceTypePhotoLibrary delegate:self];
                    pickerPresenter(vc);
                } else {
                    [CMPPhotoVideoManager.shared permissionAlertWithTitle:@"Unable to access the Photo Library" message: @"To enable access, go to Settings > Privacy > Photo Library and turn on Photo Library access for this app." presenter:^(UIViewController * _Nonnull vc) {
                        alertPresenter(vc);
                    }];
                }
            }];
        }];
        [alert addAction:alertAction];
    }
    
    if ([CMPPhotoVideoManager.shared isSourceAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [CMPPhotoVideoManager.shared requestCameraAccessWithCompletion:^(BOOL success) {
                if (success) {
                    UIImagePickerController *vc = [CMPPhotoVideoManager.shared imagePickerControllerForType:UIImagePickerControllerSourceTypeCamera delegate:self];
                    pickerPresenter(vc);
                } else {
                    [CMPPhotoVideoManager.shared permissionAlertWithTitle:@"Unable to access the Camera" message: @"To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app." presenter:^(UIViewController * _Nonnull vc) {
                        alertPresenter(vc);
                    }];
                }
            }];
        }];
        [alert addAction:alertAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    presenter(alert);
}

- (void)showPhotoCropControllerWithImage:(UIImage *)image presenter:(void (^)(UIViewController * _Nonnull))presenter {
    CMPPhotoCropViewModel *vm = [[CMPPhotoCropViewModel alloc] initWithImage:image];
    CMPPhotoCropViewController *vc = [[CMPPhotoCropViewController alloc] initWithViewModel:vm];
    presenter(vc);
}

#pragma mark - UIImagePickerControllerDelegate & UINavigationControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *editedImage = info[UIImagePickerControllerEditedImage];
        if (editedImage) {
            if (self.didTakeNewPhoto) {
                self.didTakeNewPhoto([editedImage resizeToScreenSize]);
            }
            return;
        }
        UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
        if (originalImage) {
            if (self.didTakeNewPhoto) {
                self.didTakeNewPhoto([originalImage resizeToScreenSize]);
            }
            return;
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CMPMessageStoreDelegate

- (void)didInsertMessages:(nonnull NSArray<CMPChatMessage *> *)messages {
   // NSInteger currentIndex = self.messages.count == 0 ? 0 : self.messages.count - 1;
   // NSInteger newIndex = currentIndex + messages.count == 0 ? 0 : messages.count - 1;
    @synchronized (self.messages) {
        for (CMPChatMessage *m in messages) {
            [self.messages addObject:m];
        }
    }
    
    if (self.shouldReloadData) {
        self.shouldReloadData();
    }
}

- (void)didDeleteMessages:(nonnull NSArray<NSString *> *)messageIDs {
    @synchronized (self.messages) {
        for (CMPChatMessage *existingMessage in self.messages) {
            for (NSString *id in messageIDs) {
                if ([existingMessage.id isEqualToString:id]) {
                    [self.messages removeObject:existingMessage];
                    break;
                }
            }
        }
    }
    
    if (self.shouldReloadData) {
        self.shouldReloadData();
    }
}

- (void)didUpdateMessages:(nonnull NSArray<CMPChatMessage *> *)messages {
    
}

- (void)didInsertMessageStatuses:(nonnull NSArray<CMPChatMessageStatus *> *)messageStatuses {}

- (void)didUpdateMessageStatuses:(nonnull NSArray<CMPChatMessageStatus *> *)messageStatuses {}

- (void)didDeleteMessageStatuses:(nonnull NSArray<NSString *> *)messageIDs {}

@end
