//
//  ZTSeriesWindowController.h
//  PasswordBlaster
//
//  Created by Billy Gray on 7/30/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZTSeriesWindowController : NSWindowController
@property (nonatomic, assign) IBOutlet NSTextView *textView;
@property (nonatomic, retain) NSArray *passwordsArray;
@property (nonatomic, retain) NSString *textString;
@end
