//
//  ZTAppDelegate.m
//  BL4ST3R
//
//  Created by Billy Gray on 7/29/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import "ZTAppDelegate.h"
#import "ZTGeneratorWindowController.h"

@implementation ZTAppDelegate
@synthesize windowController = _windowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    ZTGeneratorWindowController *gwc = [[ZTGeneratorWindowController alloc] init];
    self.windowController = gwc;
    [gwc release];
    [self.windowController showWindow:nil];
}

- (void)dealloc {
    [_windowController release];
    [super dealloc];
}

@end
