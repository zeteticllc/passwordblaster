//
//  ZTPasswordGenerator.h
//  BL4ST3R
//
//  Created by Billy Gray on 7/29/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZTPasswordGenerator : NSObject
@property (nonatomic) NSInteger length;
@property (nonatomic) NSInteger seriesLength;
@property (nonatomic) BOOL useExtendedUTF8Set;
@property (nonatomic) BOOL useCommonRestrictions;
@property (nonatomic, retain) NSArray *characterRanges;
+ (instancetype)sharedGenerator;
- (NSString *)generate;
- (NSArray *)generateSeries;
@end
