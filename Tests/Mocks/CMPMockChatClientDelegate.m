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

#import "CMPMockChatClientDelegate.h"

@implementation CMPMockChatClientDelegate

- (void)didUpdateProfile:(nonnull CMPProfileEventUpdate *)event {
    _profileUpdateCallback(event);
}

- (void)participantTyping:(nonnull NSString *)conversationID participantID:(nonnull NSString *)participantID isTyping:(BOOL)isTyping {
    _typingCallback(conversationID, participantID, isTyping);
}

- (void)didAddParticipant:(nonnull CMPConversationEventParticipantAdded *)event {
    _participantAddedCallback(event);
}

- (void)didRemoveParicipant:(nonnull CMPConversationEventParticipantRemoved *)event {
    _participantRemovedCallback(event);
}

- (void)didUpdateParticipant:(nonnull CMPConversationEventParticipantUpdated *)event {
    _participantUpdatedCallback(event);
}


@end

