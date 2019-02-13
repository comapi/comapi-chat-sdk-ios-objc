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

#import "CMPMessagePartCell.h"
#import "CMPImagePartView.h"
#import "CMPTextPartView.h"
#import "NSDate+CMPUtility.h"

@interface CMPMessagePartCell ()

@property (nonatomic, strong) NSMutableArray<id<CMPMessagePartConfigurable>> *partViews;

@end

@implementation CMPMessagePartCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.dateLabel = [UILabel new];
        self.partViews = [NSMutableArray new];
        
        [self configureSelf];
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self reset];
}

- (void)reset {
    for (UIView *v in self.contentView.subviews) {
        [NSLayoutConstraint deactivateConstraints:v.constraints];
        [v removeFromSuperview];
    }
    self.dateLabel.text = nil;
}

- (void)configureSelf {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
}

- (CMPPartType)partTypeForMessagePart:(CMPChatMessagePart *)messagePart {
    if ([messagePart.type isEqualToString:@"text/plain"]) {
        return CMPPartTypeText;
    } else if ([messagePart.type isEqualToString:@"image/jpeg"] ||
               [messagePart.type isEqualToString:@"image/jpg"] ||
               [messagePart.type isEqualToString:@"image/png"]) {
        return CMPPartTypeImage;
    }
    
    return CMPPartTypeUnknown;
}

- (UIView *)generatePartsView:(NSArray<CMPChatMessagePart *> *)parts {
    self.partViews = [NSMutableArray new];
    UIView *view = [UIView new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    for (int i = 0; i < parts.count; i++) {
        switch ([self partTypeForMessagePart:parts[i]]) {
            case CMPPartTypeText: {
                CMPTextPartView *partView = [[CMPTextPartView alloc] init];
                [view addSubview:partView];
                NSLayoutConstraint *top;
                if (i == 0) {
                    top = [partView.topAnchor constraintEqualToAnchor:view.topAnchor constant:0];
                } else {
                    top = [partView.topAnchor constraintEqualToAnchor:((UIView *)self.partViews[i - 1]).bottomAnchor constant:0];
                }
                NSLayoutConstraint *leading = [partView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:0];
                NSLayoutConstraint *trailing = [partView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:0];
                NSLayoutConstraint *bottom;
                if (i == parts.count - 1) {
                    bottom = [partView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-2];
                }
                
                NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
                [constraints addObject:leading];
                [constraints addObject:trailing];
                [constraints addObject:top];
                
                if (bottom) {
                    [constraints addObject:bottom];
                }
                
                [NSLayoutConstraint activateConstraints:constraints];
                [self.partViews addObject:partView];
                
                break;
            }
            case CMPPartTypeImage: {
                CMPImagePartView *partView = [[CMPImagePartView alloc] init];
                [view addSubview:partView];
                NSLayoutConstraint *top;
                if (i == 0) {
                    top = [partView.topAnchor constraintEqualToAnchor:view.topAnchor constant:0];
                } else {
                    top = [partView.topAnchor constraintEqualToAnchor:((UIView *)self.partViews[i - 1]).bottomAnchor constant:0];
                }
                NSLayoutConstraint *leading = [partView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:0];
                NSLayoutConstraint *trailing = [partView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:0];
                NSLayoutConstraint *bottom;
                if (i == parts.count - 1) {
                    bottom = [partView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-2];
                }
                
                NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
                [constraints addObject:leading];
                [constraints addObject:trailing];
                [constraints addObject:top];
                
                if (bottom) {
                    [constraints addObject:bottom];
                }
                
                [NSLayoutConstraint activateConstraints:constraints];
                [self.partViews addObject:partView];
                break;
            }
            case CMPPartTypeUnknown: {
                
                break;
            }
        }
    }
    
    return view;;
}

- (void)configureDateLabel:(NSDate *)date ownership:(CMPMessageOwnership)ownership {
    self.dateLabel.textColor = ownership == CMPMessageOwnershipSelf ? UIColor.whiteColor : UIColor.blackColor;
    self.dateLabel.textAlignment = ownership == CMPMessageOwnershipSelf ? NSTextAlignmentRight : NSTextAlignmentLeft;
    self.dateLabel.font = [UIFont systemFontOfSize:11];
    self.dateLabel.numberOfLines = 0;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.text = [date ISO8061String];
    
    [self.contentView addSubview:self.dateLabel];
    
    NSLayoutConstraint *top = [self.dateLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:1];
    NSLayoutConstraint *side;
    if (ownership == CMPMessageOwnershipSelf) {
        side = [self.dateLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14];
    } else {
        side = [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14];
    }
    
    [NSLayoutConstraint activateConstraints:@[top, side]];
}

- (void)configurePartsView:(CMPChatMessage *)message ownership:(CMPMessageOwnership)ownership downloader:(CMPImageDownloader *)downloader {
    UIView *partsView = [self generatePartsView:message.parts];
    
    [self.contentView addSubview:partsView];
    
    NSLayoutConstraint *top = [partsView.topAnchor constraintEqualToAnchor:self.dateLabel.bottomAnchor constant:4];
    NSLayoutConstraint *bottom = [partsView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8];
    bottom.priority = 999;
    
    NSLayoutConstraint *side;
    if (ownership == CMPMessageOwnershipSelf) {
        side = [partsView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:0];
    } else {
        side = [partsView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:0];
    }
    
    [NSLayoutConstraint activateConstraints:@[top, bottom, side]];
}

- (void)configureWithMessage:(CMPChatMessage *)message ownership:(CMPMessageOwnership)ownership downloader:(CMPImageDownloader *)downloader {
    [self configureDateLabel:message.context.sentOn ownership:ownership];
    [self configurePartsView:message ownership:ownership downloader:downloader];
    
    for (int i = 0; i < message.parts.count; i++) {
        if ([_partViews[i] isKindOfClass:CMPTextPartView.class]) {
            [_partViews[i] configureWithMessagePart:message.parts[i] ownership:ownership];
        } else if ([_partViews[i] isKindOfClass:CMPImagePartView.class]) {
            [_partViews[i] configureWithMessagePart:message.parts[i] ownership:ownership downloader:downloader];
        }
    }
}


@end
