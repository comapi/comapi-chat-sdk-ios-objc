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

#import "CMPChatConstants.h"

NSUInteger const CMPMaxPartDataLength = 1333;

CMPDirectoryLocation const CMPDirectoryLocationAttachments = @"attachments";

CMPPartType const CMPPartTypeUploading = @"comapi/upl";
CMPPartType const CMPPartTypeError = @"comapi/err";
CMPPartType const CMPPartTypePNG = @"image/png";
CMPPartType const CMPPartTypeJPG = @"image/jpg";
CMPPartType const CMPPartTypeBMP = @"image/bmp";
CMPPartType const CMPPartTypeText = @"text/plain";
CMPPartType const CMPPartTypePDF = @"application/pdf";
CMPPartType const CMPPartTypeDOC = @"application/msword";
CMPPartType const CMPPartTypeXLS = @"application/xml";

CMPID const CMPIDTemporaryMessage = @"ComapiMessageTempId";
CMPID const CMPIDSendingMessageStatus = @"ComapiMessageSendingStatus";

CMPChatSDKInfo const CMPChatSDKInfoVersion = @"1.0.0";
