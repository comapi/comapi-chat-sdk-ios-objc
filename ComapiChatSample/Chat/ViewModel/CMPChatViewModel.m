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

#import "CMPPhotoVideoManager.h"
#import "UIImage+CMPUtilities.h"

@implementation CMPChatViewModel

- (instancetype)initWithClient:(CMPComapiChatClient *)client store:(CMPStore *)store conversation:(CMPChatConversation *)conversation {
    self = [super init];
    
    if (self) {
        self.client = client;
        self.store = store;
        self.conversation = conversation;
        self.fetchController = [self setupFetchController];
        self.downloader = [[CMPImageDownloader alloc] init];
        self.imageAttachments = [NSMutableArray new];
    }
    
    return self;
}

- (NSFetchedResultsController *)setupFetchController {
    NSManagedObjectContext *context = CMPStoreManagerStack.shared.mainContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"context.conversationID", _conversation.id];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"context.sentOn" ascending:YES]];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc]
                                              initWithFetchRequest:fetchRequest
                                              managedObjectContext:context
                                              sectionNameKeyPath:nil
                                              cacheName:nil];
    controller.delegate = self;
    return controller;
}

- (void)getPreviousMessages:(void (^)(NSError * _Nullable))completion {
    [self.client.services.messaging getPreviousMessages:self.conversation.id completion:^(CMPChatResult * result) {
        completion(result.error);
    }];
}

- (void)getParticipantsWithCompletion:(void (^)(NSArray<CMPChatParticipant *> * _Nullable, NSError * _Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [self.client.services.messaging getParticipants:self.conversation.id completion:^(NSArray<CMPChatParticipant *> * _Nonnull participants) {
        weakSelf.participants = [NSMutableArray arrayWithArray:participants];
        completion(participants, nil);
    }];
}

- (void)synchroniseConversation:(void (^)(NSError * _Nullable))completion {
    [self.client.services.messaging synchroniseConversation:self.conversation.id completion:^(CMPChatResult * result) {
        completion(result.error);
    }];
}


- (nullable CMPChatParticipant *)otherParticipant {
    for (CMPChatParticipant *p in self.participants) {
        if (![p.id isEqualToString:_client.profileID]) {
            return p;
        }
    }
    
    return nil;
}

- (void)markReadWithCompletion:(void (^)(NSError * _Nullable))completion {
    NSArray<Message *> * messages = _fetchController.fetchedObjects;
    NSMutableArray<NSString *> *toUpdate = [NSMutableArray new];
    
    for (Message *m in messages) {
        if (m.statusUpdates.count == 0) {
            [toUpdate addObject:m.id];
        } else {
            for (MessageStatus *ms in m.statusUpdates) {
                if ([ms.profileID isEqualToString:_client.profileID] && [ms.messageStatus isEqualToNumber:@(CMPChatMessageDeliveryStatusDelivered)]) {
                    [toUpdate addObject:m.id];
                }
            }
        }
    }
    
    [self.client.services.messaging markMessagesAsRead:_conversation.id messageIDs:toUpdate completion:^(CMPChatResult * _Nonnull result) {
        if (result.error) {
            completion(result.error);
        }
    }];
}

- (NSArray<CMPChatAttachment *> *)convertImagesToAttachments {
    NSMutableArray<CMPChatAttachment *> *attachments = [NSMutableArray new];
    for (UIImage *i in _imageAttachments) {
        NSData *data = UIImageJPEGRepresentation(i, 1.0);
        CMPContentData *contentData = [[CMPContentData alloc] initWithData:data type:@"image/jpg" name:nil];
        CMPChatAttachment *attachment = [[CMPChatAttachment alloc] initWithContentData:contentData folder:@"images"];
        [attachments addObject:attachment];
    }
    
    return attachments;
}

- (CMPMessageAlert *)createAlert {
    NSDictionary<NSString *, id> *apns = @{@"alert" : @"yes",
                                           @"badge" : @(1),
                                           @"payload" : @{@"conversationId" : _conversation.id}};
    NSDictionary<NSString *, id> *fcm = @{@"\"collapse_key\"" : @"\"\"",
                                          @"badge" : @(1),
                                          @"data" : @{@"conversationId" : _conversation.id},
                                          @"notification" : @{@"body" : @"yes",
                                                              @"title" : @"New Message"}
                                          };
    CMPMessageAlertPlatforms *platforms = [[CMPMessageAlertPlatforms alloc] initWithApns:apns fcm:fcm];
    CMPMessageAlert *alert = [[CMPMessageAlert alloc] initWithPlatforms:platforms];
    return alert;
}

- (void)sendMessage:(NSString *)message completion:(void (^)(NSError * _Nullable))completion {
    NSArray<CMPChatAttachment *> *attachments = [self convertImagesToAttachments];
    if (message) {
        CMPMessagePart *textPart = [[CMPMessagePart alloc] initWithName:@"" type:@"text/plain" url:nil data:message size:@(message.length)];
        CMPSendableMessage *newMessage = [[CMPSendableMessage alloc] initWithMetadata:nil parts:@[textPart] alert:[self createAlert]];
        __weak typeof(self) weakSelf = self;
        [self.client.services.messaging sendMessage:_conversation.id message:newMessage attachments:attachments completion:^(CMPChatResult * result) {
            weakSelf.imageAttachments = [NSMutableArray new];
            completion(result.error);
        }];
    } else {
        completion(nil);
    }
}

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

#pragma mark - NSFetchResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    Message *msg = (Message *)anObject;

    NSString *profileID = msg.context.from.id;
    BOOL isMyOwn = [profileID isEqualToString:_client.profileID];
    if (type == NSFetchedResultsChangeInsert) {
        self.shouldReloadDataAtIndex(!isMyOwn, NSFetchedResultsChangeInsert, newIndexPath.row);
    } else if (type == NSFetchedResultsChangeUpdate) {
        self.shouldReloadDataAtIndex(NO, NSFetchedResultsChangeUpdate, newIndexPath.row);
    } else if (type == NSFetchedResultsChangeDelete) {
        self.shouldReloadDataAtIndex(NO, NSFetchedResultsChangeDelete, indexPath.row);
    }
}

@end
