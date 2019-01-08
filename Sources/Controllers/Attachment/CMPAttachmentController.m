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

#import "CMPAttachmentController.h"
#import "CMPChatAttachment.h"

@interface CMPAttachmentController()

@property (nonatomic, weak, nullable, readonly) CMPComapiClient *client;

@end

@implementation CMPAttachmentController

- (instancetype)initWithClient:(CMPComapiClient *)client {
    _client = client;
    
    return self;
}

- (BOOL)isConfigured {
    return _client != nil;
}

- (void)uploadAttachments:(nonnull NSArray<CMPChatAttachment *> *) attachments withCompletion: (nonnull UploadCompleted) completed {
    if ([attachments count] > 0) {
        [self uploadAttachment:attachments atIndex:0 withCompletion:completed];
    }
}

- (void)uploadAttachment:(nonnull NSArray<CMPChatAttachment *> *) attachments atIndex:(int) i withCompletion: (nonnull UploadCompleted) completed {
    CMPChatAttachment* a = [attachments objectAtIndex:i];
    [_client.services.messaging uploadContent: a.data folder: a.folder completion:^(CMPResult<CMPContentUploadResult *> * result) {
        if (a.error != nil) {
            a.error = result.error;
        } else {
            a.url = result.object.url;
        }
        int next = i+1;
        if (next < attachments.count) {
            [self uploadAttachment:attachments atIndex: next withCompletion:completed];
        } else {
            completed(attachments);
        }
    }];
}

@end
