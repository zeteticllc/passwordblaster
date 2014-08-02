//
//  ZTGeneratorWindowController.m
//  BL4ST3R
//
//  Created by Billy Gray on 7/30/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import "ZTGeneratorWindowController.h"

@interface ZTGeneratorWindowController ()
- (void)_showSuggestion:(NSString *)string;
- (void)_showSeries:(NSArray *)array;
@end

@implementation ZTGeneratorWindowController

@synthesize passwordGenerator =_passwordGenerator;
@synthesize refreshButton = _refreshButton;
@synthesize suggestionField = _suggestionField;
@synthesize progressIndicator = _progressIndicator;
@synthesize seriesButton = _seriesButton;
@synthesize seriesWindowController = _seriesWindowController;
@synthesize isGeneratingPasswords = _isGeneratingPasswords;

- (id)init {
    return [super initWithWindowNibName: @"ZTGeneratorWindowController"];
}

- (id)initWithWindowNibName:(NSString *)name {
    NSLog(@"ERROR: don't call -[%@ initWithWindowNibName:] directly, use init instead, designed for one xib file only", [self class]);
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // over-ride point for UI intialization, but the xib loads lazy so call self.window before attempting to update UI
    [self loadWindow];
    self.isGeneratingPasswords = NO;
    // get the series window controller and window loaded up
    if (self.seriesWindowController == nil) {
        ZTSeriesWindowController *swc = [[ZTSeriesWindowController alloc] init];
        self.seriesWindowController = swc;
        [swc release];
    }
    // generate a password
    [self refreshSuggestion:nil];
    // configure generator from NSUserDefaults
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    self.passwordGenerator.length = [defaults integerForKey:@"ZTPGlength"];
//    self.passwordGenerator.seriesLength = [defaults integerForKey:@"ZTPGseriesLength"];
//    self.passwordGenerator.useExtendedUTF8Set = [defaults boolForKey:@"ZTPGuseExtendedUTF8Set"];
//    self.passwordGenerator.useCommonRestrictions = [defaults boolForKey:@"ZTPGuseCommonRestrictions"];
}

- (IBAction)refreshSuggestion:(id)sender {
    // this will cause our other controls to setEnabled:NO via bindings
    self.isGeneratingPasswords = YES;
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_async(defaultQueue, ^{
        NSString *answer = [self.passwordGenerator generate];
        [self performSelectorOnMainThread:@selector(_showSuggestion:) withObject:answer waitUntilDone:NO];
    });
}

- (IBAction)generateSeries:(id)sender {
    self.isGeneratingPasswords = YES;
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	dispatch_async(defaultQueue, ^{
        NSArray *series = [self.passwordGenerator generateSeries];
        [self performSelectorOnMainThread:@selector(_showSeries:) withObject:series waitUntilDone:NO];
    });
}

- (void)_showSuggestion:(NSString *)string {
    self.isGeneratingPasswords = NO;
    [self.progressIndicator stopAnimation:nil];
    if (string != nil && [string length] > 0) {
        [self.suggestionField setStringValue:string];
    }
    [self.refreshButton setHidden:NO];
//    [self.window makeFirstResponder:self.suggestionField];
}

- (void)_showSeries:(NSArray *)array {
    self.isGeneratingPasswords = NO;
    self.seriesWindowController.passwordsArray = array;
    if ([self.seriesWindowController isWindowLoaded] == NO) {
        [self.seriesWindowController window];
    }
    [self.seriesWindowController windowDidLoad];
    [self.seriesWindowController showWindow:nil];
}

- (void)dealloc {
    [_passwordGenerator release];
    [_seriesWindowController release];
    [super dealloc];
}

@end
