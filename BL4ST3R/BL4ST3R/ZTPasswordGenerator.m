//
//  ZTPasswordGenerator.m
//  BL4ST3R
//
//  Created by Billy Gray on 7/29/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import "ZTPasswordGenerator.h"

typedef struct ZTCharacterRange {
    NSInteger start;
    NSInteger end;
} ZTCharacterRange;

ZTCharacterRange ZTMakeCharacterRange(NSInteger start, NSInteger end) {
    ZTCharacterRange range = { .start = start, .end = end };
    return range;
}

static const NSString *kLatinMetacharacterSet = @"!@#%&*_+-=;<>,./?;:{}/|~";

@interface ZTPasswordGenerator ()
@property (nonatomic) BOOL includesOneLatinUppercase;
@property (nonatomic) BOOL includesOneLatinLowercase;
@property (nonatomic) BOOL includesOneLatinNumber;
@property (nonatomic) BOOL includesOneLatinMetacharacter;
@property (nonatomic) BOOL excludesRepeats;
@property (nonatomic) unichar previousCharacter;
- (NSString *)_generate;
@end

@implementation ZTPasswordGenerator

@synthesize length = _length;
@synthesize seriesLength = _seriesLength;
@synthesize useExtendedUTF8Set = _useExtendedUTF8Set;
@synthesize useCommonRestrictions = _useCommonRestrictions;
@synthesize characterRanges = _characterRanges;

- (id)init {
    self = [super init];
    if (self != nil) {
        _length = 16;
        _seriesLength = 10;
        _useExtendedUTF8Set = YES;
        _useCommonRestrictions = NO;
        _characterRanges = nil;
    }
    return self;
}

static ZTPasswordGenerator *__sharedGenerator = nil;

+ (instancetype)sharedGenerator {
    if (__sharedGenerator == nil) {
        __sharedGenerator = [[self alloc] init];
    }
    return __sharedGenerator;
}

- (NSString *)generate {
    return [self _generate];
}

- (NSArray *)generateSeries {
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:self.seriesLength];
    for (NSInteger i = 0; i < self.seriesLength; i++) {
        [mutableArray addObject:[self _generate]];
    }
    NSArray *array = [NSArray arrayWithArray:mutableArray];
    return array;
}

- (NSString *)_generate {
    NSString *password = nil;
    if (self.characterRanges == nil) {
        NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"ZTUTF8CharacterRanges" withExtension:@"plist"];
        if (plistURL != nil) {
            self.characterRanges = [NSArray arrayWithContentsOfURL:plistURL];
        } else {
            NSLog(@"Warning: unable to load ZTUTF8CharacterRanges.plist");
        }
    }
    // before we declare our C array, we need an accurate count of available chars for allocation
    NSInteger setSize = 0;
    for (NSDictionary *dict in self.characterRanges) {
        NSInteger start = [[dict objectForKey:@"start"] integerValue];
        NSInteger end = [[dict objectForKey:@"end"] integerValue];
        NSInteger size = (end + 1) - start;
        setSize += size;
        // only process the first set? (basic latin expected to be at index 0 in rangesArray)
        if (self.useExtendedUTF8Set == NO) {
            break;
        }
    }
    NSInteger availableCharacters[setSize];
    NSInteger arrayIdx = 0;
    for (NSDictionary *dict in self.characterRanges) {
        NSInteger start = [[dict objectForKey:@"start"] integerValue];
        NSInteger end = [[dict objectForKey:@"end"] integerValue];
        for (NSInteger i = start; i <= end; i++) {
            availableCharacters[arrayIdx] = i;
            ++arrayIdx;
        }
        // only process the first set? (basic latin expected to be at index 0 in rangesArray)
        if (self.useExtendedUTF8Set == NO) {
            break;
        }
    }
    BOOL filtered = NO;
    do {
        password = [self _randomStringFromCharacters:availableCharacters
                                             setSize:setSize];
        if (self.useCommonRestrictions) {
            if ([self _stringPassesFilters:password]) {
                filtered = YES;
            }
        } else { // if we're not filtering, set our flag to YES to end the while loop
            filtered = YES;
        }
    } while (filtered == NO);
    return password;
}

- (BOOL)_stringPassesFilters:(NSString *)string {
    self.includesOneLatinUppercase      = NO;
    self.includesOneLatinLowercase      = NO;
    self.includesOneLatinNumber         = NO;
    self.includesOneLatinMetacharacter  = NO;
    self.excludesRepeats                = YES;
//    ZTCharacterRange lowercaseLatin = ZTMakeCharacterRange(0x0061, 0x007A);
//    ZTCharacterRange uppercaseLatin = ZTMakeCharacterRange(0x0041, 0x005A);
//    ZTCharacterRange decimalLatin = ZTMakeCharacterRange(0x0030, 0x0039);
    
    /*
     * Following trick allows us to correctly enumerate over composed character sequences
     * Ole Begemann, I could kiss you
     * http://www.objc.io/issue-9/unicode.html
     */
    NSRange fullRange = NSMakeRange(0, [string length]);
    [string enumerateSubstringsInRange:fullRange
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                unichar ch = [substring characterAtIndex:0];
                                if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:ch]) {
                                    self.includesOneLatinUppercase = YES;
                                }
                                if ([[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:ch]) {
                                    self.includesOneLatinLowercase = YES;
                                }
                                if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch]) {
                                    self.includesOneLatinNumber = YES;
                                }
                                if ([[NSCharacterSet punctuationCharacterSet] characterIsMember:ch]) {
                                    self.includesOneLatinMetacharacter = YES;
                                }
                                if (ch == self.previousCharacter) {
                                    self.excludesRepeats = NO;
                                }
                                self.previousCharacter = ch;
                            }];
    if (self.includesOneLatinMetacharacter &&
        self.includesOneLatinNumber &&
        self.includesOneLatinUppercase &&
        self.includesOneLatinLowercase &&
        self.excludesRepeats == YES) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)_randomStringFromCharacters:(NSInteger[])characters
                                  setSize:(NSInteger)setSize {
    NSInteger bytesNeeded = self.length * sizeof(NSInteger);
    // set up some random data via Common Crypto / Security.framework
    NSMutableData *data = [NSMutableData dataWithCapacity:bytesNeeded];
    SecRandomCopyBytes(kSecRandomDefault, bytesNeeded, [data mutableBytes]);
    NSMutableString *password = [NSMutableString stringWithCapacity:self.length];
    for (NSInteger i = 0; i < self.length; i++) {
        unichar ch;
        ch = [self _characterFromRandomData:data
                                 characters:characters
                                    setSize:setSize
                                   forIndex:i];
        [password appendFormat:@"%C", ch];
    }
    // don't return a mutable
    return [NSString stringWithString:password];
}

- (unichar)_characterFromRandomData:(NSMutableData *)data
                         characters:(NSInteger[])characters
                            setSize:(NSInteger)setSize
                           forIndex:(NSInteger)idx {
    unichar ch;
    unsigned int *randomInt = (unsigned int *) &[data mutableBytes][idx*sizeof(int)];
    unsigned int randomIndex = *randomInt % setSize;
    ch = (unichar)characters[randomIndex];
    return ch;
}

- (void)dealloc {
    [_characterRanges release];
    [super dealloc];
}

@end
