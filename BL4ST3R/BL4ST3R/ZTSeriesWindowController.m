//
//  ZTSeriesWindowController.m
//  PasswordBlaster
//
//  Created by Billy Gray on 7/30/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import "ZTSeriesWindowController.h"

@interface ZTSeriesWindowController ()

@end

@implementation ZTSeriesWindowController
@synthesize textView = _textView;
@synthesize passwordsArray = _passwordsArray;
@synthesize textString = _textString;

- (id)init {
    return [super initWithWindowNibName:@"ZTSeriesWindowController"];
}

- (id)initWithWindowNibName:(NSString *)name {
    NSLog(@"ERROR: don't call -[%@ initWithWindowNibName:] directly, use init instead, designed for one xib file only", [self class]);
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSString *text = [self.passwordsArray componentsJoinedByString:@"\n"];
    if (text != nil && [text length] > 0) {
        self.textString = text;
    }
}

- (IBAction)cancel:(id)sender {
    [self close];
    self.passwordsArray = nil;
    self.textString = nil;
}

- (void)dealloc {
    [_textString release];
    [_passwordsArray release];
    [super dealloc];
}

@end
