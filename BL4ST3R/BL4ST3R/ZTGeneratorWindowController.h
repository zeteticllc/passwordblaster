//
//  ZTGeneratorWindowController.h
//  BL4ST3R
//
//  Created by Billy Gray on 7/30/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZTPasswordGenerator.h"
#import "ZTSeriesWindowController.h"

@interface ZTGeneratorWindowController : NSWindowController
@property (nonatomic, retain) IBOutlet ZTPasswordGenerator *passwordGenerator;
@property (nonatomic, assign) IBOutlet NSButton *refreshButton;
@property (nonatomic, assign) IBOutlet NSTextField *suggestionField;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, assign) IBOutlet NSButton *seriesButton;
@property (nonatomic, retain) ZTSeriesWindowController *seriesWindowController;
@property (nonatomic) BOOL isGeneratingPasswords;
- (IBAction)refreshSuggestion:(id)sender;
- (IBAction)generateSeries:(id)sender;
@end
