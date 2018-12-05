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

#import "CMPChatViewController.h"
#import "CMPAddParticipantsViewController.h"
#import "CMPMessagePartCell.h"
#import "CMPAttachmentCell.h"
#import "CMPConversationsViewController.h"

#import "AppDelegate.h"

@interface CMPChatViewController ()

@end

@implementation CMPChatViewController 

- (instancetype)initWithViewModel:(CMPChatViewModel *)viewModel {
    self = [super init];
    
    if (self) {
        _viewModel = viewModel;
        
        [self navigation];
        [self delegates];
    }
    
    return self;
}

- (CMPChatView *)chatView {
    return (CMPChatView *)self.view;
}

- (void)loadView {
    self.view = [[CMPChatView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    
    __weak typeof(self) weakSelf = self;
    [weakSelf.viewModel getPreviousMessages:^(NSError * _Nullable err) {
        if (err) {
            NSLog(@"%@", err.localizedDescription);
        }
        [weakSelf.viewModel getParticipantsWithCompletion:^(NSArray<CMPChatParticipant *> * _Nullable participants, NSError * _Nullable error) {
            [weakSelf.viewModel.fetchController performFetch:&error];
            [weakSelf reload:NO];
            [weakSelf scrollToLastIndex];
        }];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewModel.shouldReloadAttachments();
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterFromKeyboardNotifications];
}

- (void)delegates {
    self.chatView.tableView.delegate = self;
    self.chatView.tableView.dataSource = self;
    self.chatView.attachmentsView.collectionView.delegate = self;
    self.chatView.attachmentsView.collectionView.dataSource = self;
    
    __weak typeof(self) weakSelf = self;
    self.keyboardWillShow = ^(NSNotification * _Nonnull notif) {
        [weakSelf.chatView animateOnKeyboardChangeWithNotification:notif completion:nil];
    };
    self.keyboardWillHide = ^(NSNotification * _Nonnull notif) {
        [weakSelf.chatView animateOnKeyboardChangeWithNotification:notif completion:nil];
    };
    self.chatView.didTapSendButton = ^(NSString * _Nonnull text) {
        [weakSelf.chatView.inputMessageView endEditing];
        [weakSelf.viewModel sendMessage:text completion:^(NSError * _Nullable error) {
            weakSelf.viewModel.shouldReloadAttachments();
        }];
    };
    self.chatView.didBeginEditing = ^{
        [weakSelf.viewModel markReadWithCompletion:^(NSError * _Nullable error) {
            
        }];
    };
    self.chatView.didTapUploadButton = ^{
        [weakSelf.viewModel showPhotoSourceControllerWithPresenter:^(UIViewController * _Nonnull vc) {
            [weakSelf.navigationController presentViewController:vc animated:YES completion:nil];
        } alertPresenter:^(UIViewController * _Nonnull vc) {
            [weakSelf.navigationController presentViewController:vc animated:YES completion:nil];
        } pickerPresenter:^(UIViewController * _Nonnull vc) {
            [weakSelf.navigationController presentViewController:vc animated:YES completion:nil];
        }];
    };
    self.viewModel.shouldReloadDataAtIndex = ^(BOOL showNewMessage, NSFetchedResultsChangeType changeType, NSInteger idx) {
        NSArray *indices = @[[NSIndexPath indexPathForRow:idx inSection:0]];
        [UIView performWithoutAnimation:^{
            switch (changeType) {
                case NSFetchedResultsChangeInsert: {
                    [weakSelf.chatView.tableView insertRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
                case NSFetchedResultsChangeDelete: {
                    [weakSelf.chatView.tableView deleteRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
                case NSFetchedResultsChangeUpdate:
                    [weakSelf.chatView.tableView reloadRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
                    break;
                default:
                    break;
            }
        }];
        
        if (showNewMessage) {
            if (weakSelf.chatView.tableView.contentOffset.y < weakSelf.chatView.tableView.contentSize.height) {
                [weakSelf.chatView showNewMessageView:YES completion:nil];
            }
        } else {
            [weakSelf scrollToLastIndex];
        }
    };
    self.viewModel.shouldReloadData = ^(BOOL showNewMessage) {
        if (!showNewMessage) {
            [weakSelf reload:NO];
            [weakSelf scrollToLastIndex];
        } else {
            [weakSelf reload:YES];
        }
    };
    self.chatView.didTapNewMessageButton = ^{
        [weakSelf scrollToLastIndex];
        [weakSelf.chatView showNewMessageView:NO completion:^{
            [weakSelf.viewModel markReadWithCompletion:^(NSError * _Nullable err) {
                
            }];
        }];
    };
    self.viewModel.didTakeNewPhoto = ^(UIImage * _Nonnull image) {
        [weakSelf.viewModel showPhotoCropControllerWithImage:image presenter:^(UIViewController * _Nonnull vc) {
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }];
    };
    self.viewModel.shouldReloadAttachments = ^{
        if (weakSelf.viewModel.imageAttachments.count > 0) {
            [weakSelf.chatView showAttachmentsWithCompletion:^{
                [weakSelf.chatView reloadAttachments];
                [weakSelf.chatView adjustTableViewContentInset];
            }];
        } else if (weakSelf.viewModel.imageAttachments.count == 0) {
            [weakSelf.chatView hideAttachmentsWithCompletion:^{
                [weakSelf.chatView reloadAttachments];
                [weakSelf.chatView adjustTableViewContentInset];
            }];
        }
    };
}

- (void)navigation {
    self.title = _viewModel.conversation.name;
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [backButton setImage:[UIImage imageNamed:@"back"] forState:0];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    self.navigationItem.leftBarButtonItem = backBarButton;
    
    UIButton *addParticipantButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [addParticipantButton setImage:[UIImage imageNamed:@"add"] forState:0];
    [addParticipantButton addTarget:self action:@selector(addParticipant) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *addParticipantBarButton = [[UIBarButtonItem alloc] initWithCustomView:addParticipantButton];
    
    self.navigationItem.rightBarButtonItem = addParticipantBarButton;
}

- (void)reload:(BOOL)showNewMessageView {
    [self.chatView.tableView reloadData];
    if (showNewMessageView) {
        if (self.chatView.tableView.contentOffset.y < self.chatView.tableView.contentSize.height) {
            [self.chatView showNewMessageView:YES completion:nil];
        }
    }
}

- (void)back {
    AppDelegate *del = (AppDelegate *)UIApplication.sharedApplication.delegate;
    UINavigationController *nav = (UINavigationController *)del.window.rootViewController;
    CMPConversationsViewController *vc = nav.viewControllers[1];
    vc.loadContent = YES;
    [nav popViewControllerAnimated:YES];
}

- (void)scrollToLastIndex {
    if (self.viewModel.fetchController.sections[0].numberOfObjects == 0) {
        return;
    }
    NSInteger index = self.viewModel.fetchController.sections[0].numberOfObjects - 1;
    [self.chatView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)addParticipant {
    CMPAddParticipantsViewModel *vm = [[CMPAddParticipantsViewModel alloc] initWithClient:_viewModel.client store:_viewModel.store conversationID:_viewModel.conversation.id];
    CMPAddParticipantsViewController *vc = [[CMPAddParticipantsViewController alloc] initWithViewModel:vm];
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[_viewModel.fetchController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[_viewModel.fetchController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[_viewModel.fetchController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CMPChatMessage *msg = [[_viewModel.fetchController objectAtIndexPath:indexPath] chatMessage];
    CMPMessagePartCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSString *fromID = msg.context.from.id;
    NSString *selfID = _viewModel.client.profileID;

    BOOL isMine = [fromID isEqualToString:selfID];
    [cell configureWithMessage:msg participants:_viewModel.participants ownership:isMine ? CMPMessageOwnershipSelf : CMPMessageOwnershipOther downloader:_viewModel.downloader];

    return cell;
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.imageAttachments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CMPAttachmentCell *cell = (CMPAttachmentCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell configureWithImage:self.viewModel.imageAttachments[indexPath.row]];
    cell.didTapDelete = ^{
        [self.viewModel.imageAttachments removeObjectAtIndex:indexPath.row];
        self.viewModel.shouldReloadAttachments();
    };
    return cell;
}

@end
