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

#import "CMPChatRoles.h"

@implementation CMPChatRoles

- (instancetype)initWithOwnerAttributes:(CMPChatRoleAttributes *)ownerAttributes participantAttributes:(CMPChatRoleAttributes *)participantAttributes {
    self = [super init];
    
    if (self) {
        self.ownerAttributes = ownerAttributes;
        self.participantAttributes = participantAttributes;
    }
    
    return self;
}

- (instancetype)initWithRoles:(CMPRoles *)roles {
    self = [super init];
    
    if (self) {
        self.ownerAttributes = [[CMPChatRoleAttributes alloc] initWithRoleAttributes:roles.owner];
        self.participantAttributes = [[CMPChatRoleAttributes alloc] initWithRoleAttributes:roles.participant];
    }
    
    return self;
}

#pragma mark - CMPJSONRepresentable

- (id)json {
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary new];
    
    [dict setValue:[self.ownerAttributes json] forKey:@"ownerAttributes"];
    [dict setValue:[self.participantAttributes json] forKey:@"participantAttributes"];
    
    return dict;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    CMPChatRoles *copy = [[CMPChatRoles alloc] init];
    
    copy.ownerAttributes = [self.ownerAttributes copy];
    copy.participantAttributes = [self.participantAttributes copy];
    
    return copy;
}

@end
