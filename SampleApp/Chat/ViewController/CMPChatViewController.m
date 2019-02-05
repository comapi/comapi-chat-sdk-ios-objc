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
#import "CMPChatTextMessageCell.h"
#import "CMPChatImageMessageCell.h"
#import "CMPAddParticipantsViewController.h"

@interface CMPChatViewController ()

@end

@implementation CMPChatViewController 

- (instancetype)initWithViewModel:(CMPChatViewModel *)viewModel {
    self = [super init];
    
    if (self) {
        _viewModel = viewModel;
        _viewModel.fetchController.delegate = self;
        
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
    [weakSelf.viewModel getPreviousMessages:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        [weakSelf reload];
    }];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterFromKeyboardNotifications];
}

- (void)delegates {
    self.chatView.tableView.delegate = self;
    self.chatView.tableView.dataSource = self;
    
    __weak typeof(self) weakSelf = self;
    self.keyboardWillShow = ^(NSNotification * _Nonnull notif) {
        [weakSelf.chatView animateOnKeyboardChangeWithNotification:notif completion:nil];
    };
    self.keyboardWillHide = ^(NSNotification * _Nonnull notif) {
        [weakSelf.chatView animateOnKeyboardChangeWithNotification:notif completion:nil];
    };
    self.chatView.didTapSendButton = ^(NSString * _Nonnull text) {
        [weakSelf.viewModel sendMessage:text attachments:@[] completion:^(NSError * _Nullable error) {
            [weakSelf reload];
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
    self.viewModel.didTakeNewPhoto = ^(UIImage * _Nonnull image) {
        [weakSelf.viewModel showPhotoCropControllerWithImage:image presenter:^(UIViewController * _Nonnull vc) {
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }];
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

- (void)reload {
    NSError *err;
    [self.viewModel.fetchController performFetch:&err];
    if (err) {
        NSLog(@"%@", err.localizedDescription);
    }
    [self.chatView.tableView reloadData];
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
    CMPChatMessage *msg = [_viewModel.fetchController objectAtIndexPath:indexPath];
    if (msg.parts.firstObject.url) {
        CMPChatImageMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath];
        
        NSString *fromID = msg.context.from.id;
        NSString *selfID = _viewModel.client.profileID;
        
        BOOL isMine = [fromID isEqualToString:selfID];
        [cell configureWithMessage:msg ownership:isMine ? CMPMessageOwnershipSelf : CMPMessageOwnershipOther downloader:_viewModel.downloader animate:NO];

        return cell;
    } else {
        CMPChatTextMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textCell" forIndexPath:indexPath];
        
        NSString *fromID = msg.context.from.id;
        NSString *selfID = _viewModel.client.profileID;
        BOOL isMine = [fromID isEqualToString:selfID];
        [cell configureWithMessage:msg ownership:isMine ? CMPMessageOwnershipSelf : CMPMessageOwnershipOther];
        
        return cell;
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.chatView.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.chatView.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeMove: {
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.chatView.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        }
    }
}

@end
