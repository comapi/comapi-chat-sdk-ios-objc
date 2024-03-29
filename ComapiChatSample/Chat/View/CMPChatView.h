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

#import "CMPBaseView.h"
#import "CMPChatInputView.h"
#import "CMPAttachmentsView.h"
#import "CMPNewMessageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatView : CMPBaseView <CMPViewConfiguring>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CMPChatInputView *inputMessageView;
@property (nonatomic, strong) CMPAttachmentsView *attachmentsView;
@property (nonatomic, strong) CMPNewMessageView *messageView;

@property (nonatomic, copy, nullable) void(^didTapSendButton)(NSString *);
@property (nonatomic, copy, nullable) void(^didTapUploadButton)(void);
@property (nonatomic, copy, nullable) void(^didTapNewMessageButton)(void);
@property (nonatomic, copy, nullable) void(^didBeginEditing)(void);

@property (nonatomic, strong) NSLayoutConstraint *animatableConstraint;

- (instancetype)init;

- (void)reloadAttachments;
- (void)showNewMessageView:(BOOL)show completion:(void (^ _Nullable)(void))completion;
- (void)showAttachmentsWithCompletion:(void (^)(void))completion;
- (void)hideAttachmentsWithCompletion:(void (^)(void))completion;

- (void)animateOnKeyboardChangeWithNotification:(NSNotification *)notification completion:(void(^_Nullable)(void))completion;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)adjustTableViewContentInset;


@end

NS_ASSUME_NONNULL_END
