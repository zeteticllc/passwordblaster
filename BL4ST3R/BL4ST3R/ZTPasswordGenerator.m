//
//  ZTPasswordGenerator.m
//  BL4ST3R
//
//  Created by Billy Gray on 7/29/14.
//  Copyright (c) 2014 Zetetic. All rights reserved.
//

#import "ZTPasswordGenerator.h"
#import <Security/SecRandom.h>

typedef struct ZTCharacterRange {
    NSInteger start;
    NSInteger end;
} ZTCharacterRange;

ZTCharacterRange ZTMakeCharacterRange(NSInteger start, NSInteger end) {
    ZTCharacterRange range = { .start = start, .end = end };
    return range;
}

@interface ZTPasswordGenerator ()
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
        _length = 12;
        _seriesLength = 10;
        _useExtendedUTF8Set = YES;
        _useCommonRestrictions = YES;
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
    static NSString *kLatinMetacharacterSet = @"!@#%&*_+-=;<>,./?;:{}/|~";
    static NSString *kLatinDecimalSet = @"0123456789";
    static NSString *kLatinUppercaseSet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    static NSString *kLatinLowercaseSet = @"abcdefghijklmnopqrstuvwxyz";
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
    // here we actually generate the random password
    password = [self _randomStringFromCharacters:availableCharacters
                                         setSize:setSize];
    if (self.useCommonRestrictions) {
        password = [self _stringFromString:password withACharacterFromSet:kLatinMetacharacterSet];
        password = [self _stringFromString:password withACharacterFromSet:kLatinUppercaseSet];
        password = [self _stringFromString:password withACharacterFromSet:kLatinLowercaseSet];
        password = [self _stringFromString:password withACharacterFromSet:kLatinDecimalSet];
    }
    return password;
}

- (NSString *)_stringFromString:(NSString *)string withACharacterFromSet:(NSString *)characterString {
    NSCharacterSet *metacharSet = [NSCharacterSet characterSetWithCharactersInString:characterString];
    if ([string rangeOfCharacterFromSet:metacharSet].location == NSNotFound) {
        // generate a random character from this set
        unichar ch = [self _randomCharacterFromString:characterString];
        // for now append to the end because we may need the other chars in the string as well
//        string = [string stringByAppendingFormat:@"%C", ch];
        // now pick a random index in the password to drop this guy
        string = [self _stringByRandomlyInsertingCharacter:ch intoString:string];
    }
    return string;
}

- (NSString *)_stringByRandomlyInsertingCharacter:(unichar)character intoString:(NSString *)string {
    // generate a random index
    NSInteger setSize = [string length];
    unsigned int randomIndex = [self _randomIndexForSetSize:setSize];
    NSString *insertString = [NSString stringWithFormat:@"%C", character];
    NSMutableString *copiedString = [[string mutableCopy] autorelease];
    [copiedString insertString:insertString atIndex:randomIndex];
//    NSString *result = [string stringByReplacingCharactersInRange:NSMakeRange(randomIndex, 1) withString:insertString];
    return [NSString stringWithString:copiedString];
}

- (unichar)_randomCharacterFromString:(NSString *)string {
    // generate a random character from this set
    NSInteger setSize = [string length];
    unichar ch = [string characterAtIndex:[self _randomIndexForSetSize:setSize]];
    return ch;
}

- (unsigned int)_randomIndexForSetSize:(NSInteger)size {
    NSInteger bytesNeeded = 1 * sizeof(NSInteger);
    NSMutableData *data = [NSMutableData dataWithCapacity:bytesNeeded];
    SecRandomCopyBytes(kSecRandomDefault, bytesNeeded, [data mutableBytes]);
    unsigned int *randomInt = (unsigned int *) &[data mutableBytes][0];
    unsigned int randomIndex = *randomInt % size;
    return randomIndex;
}

- (NSString *)_randomStringFromCharacters:(NSInteger[])characters
                                  setSize:(NSInteger)setSize {
    NSInteger bytesNeeded = self.length * sizeof(NSInteger);
    // set up some random data via Common Crypto / Security.framework
    NSMutableData *data = [NSMutableData dataWithCapacity:bytesNeeded];
    SecRandomCopyBytes(kSecRandomDefault, bytesNeeded, [data mutableBytes]);
    NSMutableString *password = [NSMutableString stringWithCapacity:self.length];
    // we set it to -1 so it's not an unitialized value and to handle the first pass
    unichar previousCharacter = -1;
    for (NSInteger i = 0; i < self.length; i++) {
        unichar ch;
        ch = [self _characterFromRandomData:data
                                 characters:characters
                                    setSize:setSize
                                   forIndex:i];
        while (self.useCommonRestrictions && ch == previousCharacter) {
            NSInteger idx = [self _randomIndexForSetSize:setSize];
            ch = [self _characterFromRandomData:data
                                     characters:characters
                                        setSize:setSize
                                       forIndex:idx];
        }
        [password appendFormat:@"%C", ch];
        previousCharacter = ch;
    }
    // don't return a mutable
    return [NSString stringWithString:password];
}

- (unichar)_characterFromRandomData:(NSMutableData *)data
                         characters:(NSInteger[])characters
                            setSize:(NSInteger)setSize
                           forIndex:(NSInteger)idx {
    unichar ch;
    unsigned int *randomInt = (unsigned int *) &[data mutableBytes][idx*sizeof(NSInteger)];
    unsigned int randomIndex = *randomInt % setSize;
    ch = (unichar)characters[randomIndex];
    return ch;
}

- (void)dealloc {
    [_characterRanges release];
    [super dealloc];
}

@end
