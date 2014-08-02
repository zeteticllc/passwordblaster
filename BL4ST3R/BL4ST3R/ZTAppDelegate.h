//
//  ZTAppDelegate.h
//  BL4ST3R
//
//  Created by Billy Gray on 7/29/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ZTGeneratorWindowController;

@interface ZTAppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, retain) ZTGeneratorWindowController *windowController;
@end
