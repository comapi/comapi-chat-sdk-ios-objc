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

@import CMPComapiFoundation;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const CMPMaxPartDataLength NS_SWIFT_NAME(MaxPartDataLength);

typedef NSString * CMPDirectoryLocation NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DirectoryLocation);

extern CMPDirectoryLocation const CMPDirectoryLocationAttachments NS_SWIFT_NAME(attachments);

typedef NSString * CMPPartType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(PartType);

extern CMPPartType const CMPPartTypeUploading NS_SWIFT_NAME(uploading);
extern CMPPartType const CMPPartTypeError NS_SWIFT_NAME(error);
extern CMPPartType const CMPPartTypePNG NS_SWIFT_NAME(png);
extern CMPPartType const CMPPartTypeJPG NS_SWIFT_NAME(jpg);
extern CMPPartType const CMPPartTypeBMP NS_SWIFT_NAME(bmp);
extern CMPPartType const CMPPartTypeText NS_SWIFT_NAME(text);
extern CMPPartType const CMPPartTypePDF NS_SWIFT_NAME(pdf);
extern CMPPartType const CMPPartTypeDOC NS_SWIFT_NAME(doc);
extern CMPPartType const CMPPartTypeXLS NS_SWIFT_NAME(xls);

typedef NSString * CMPID NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ID);

extern CMPID const CMPIDTemporaryMessage NS_SWIFT_NAME(temporaryMessage);
extern CMPID const CMPIDSendingMessageStatus NS_SWIFT_NAME(sendingMessageStatus);

typedef NSString * CMPChatSDKInfo NS_TYPED_ENUM NS_SWIFT_NAME(ChatSDKInfo);

extern CMPChatSDKInfo const CMPChatSDKInfoVersion NS_SWIFT_NAME(version);

NS_ASSUME_NONNULL_END
