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

#import "CMPMIMEParser.h"

@implementation CMPMIMEParser

+ (CMPMIMEType)parseForString:(NSString *)string {
    if ([string isEqualToString:CMPPartTypePNG]) {
        return CMPMIMETypePNG;
    } else if ([string isEqualToString:CMPPartTypeJPG]) {
        return CMPMIMETypeJPG;
    } else if ([string isEqualToString:CMPPartTypeText]) {
        return CMPMIMETypeText;
    } else if ([string isEqualToString:CMPPartTypeBMP]) {
        return CMPMIMETypeBMP;
    } else if ([string isEqualToString:CMPPartTypeUploading]) {
        return CMPMIMETypeComapiUpload;
    } else if ([string isEqualToString:CMPPartTypeError]) {
        return CMPMIMETypeComapiError;
    } else if ([string isEqualToString:CMPPartTypePDF]) {
        return CMPMIMETypePDF;
    } else if ([string isEqualToString:CMPPartTypeDOC]) {
        return CMPMIMETypeDOC;
    } else if ([string isEqualToString:CMPPartTypeXLS]) {
        return CMPMIMETypeXLS;
    } else {
        return CMPMIMETypeUnknown;
    }
}

+ (CMPPartType)parseForType:(CMPMIMEType)type {
    switch (type) {
        case CMPMIMETypePNG:
            return CMPPartTypePNG;
        case CMPMIMETypeText:
            return CMPPartTypeText;
        case CMPMIMETypeJPG:
            return CMPPartTypeJPG;
        case CMPMIMETypeComapiUpload:
            return CMPPartTypeUploading;
        case CMPMIMETypeComapiError:
            return CMPPartTypeError;
        case CMPMIMETypeBMP:
            return CMPPartTypeBMP;
        case CMPMIMETypePDF:
            return CMPPartTypePDF;
        case CMPMIMETypeDOC:
            return CMPPartTypeDOC;
        case CMPMIMETypeXLS:
            return CMPPartTypeXLS;
        case CMPMIMETypeUnknown:
            return @"type/unknown";
    }
}

@end
