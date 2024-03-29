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

#import "CMPInsetTextField.h"

#import "UIToolbar+CMPUtilities.h"

@implementation CMPInsetTextField

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    [self configure];
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
}

- (void)configure {
    self.keyboardAppearance = UIKeyboardAppearanceDark;
    self.layer.cornerRadius = 4.0;
    self.backgroundColor = UIColor.clearColor;
    self.textColor = UIColor.grayColor;
    self.font = [UIFont systemFontOfSize:16];
    [self addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
    self.inputAccessoryView = [UIToolbar toolbarWithTitle:@"Done" target:self action:@selector(dismiss)];
}

- (void)textChanged {
    if (self.didChangeText) {
        self.didChangeText(self.text);
    }
}

- (void)dismiss {
    [self resignFirstResponder];
}

@end
