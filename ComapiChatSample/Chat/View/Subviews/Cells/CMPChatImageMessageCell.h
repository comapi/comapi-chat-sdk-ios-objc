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

#import "CMPBaseCell.h"
#import "CMPViewConfiguring.h"
#import "CMPChatMessage.h"
#import "CMPImageDownloader.h"
#import "CMPMessageOwnership.h"

NS_ASSUME_NONNULL_BEGIN

@interface CMPChatImageMessageCell : CMPBaseCell <CMPViewConfiguring>

@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UIActivityIndicatorView *loader;

- (void)configureWithMessage:(CMPChatMessage *)message ownership:(CMPMessageOwnership)ownership downloader:(CMPImageDownloader *)downloader animate:(BOOL)animate;

@end

NS_ASSUME_NONNULL_END
