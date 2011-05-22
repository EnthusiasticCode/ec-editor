//
//  HexFiendDataSource.m
//  HexFiendiOS
//
//  Created by Uri Baghin on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendDataSource.h"
#import "HFByteArray.h"
#import "HFBTreeByteArray.h"
#import "HFFileReference.h"
#import "HFFileByteSlice.h"
#import "HFSharedMemoryByteSlice.h"
#import "HFFunctions.h"
#import "ECCodeView.h"

@interface HexFiendDataSource ()
{
    unsigned long long cacheLineCurrentByteOffset;
    NSUInteger cacheLineCurrentUTF8Offset;
    unsigned long long cacheLineCurrentLineByteOffset;
    unsigned long long cacheLineCurrentLineUTF8Offset;
    unsigned char *cacheLineCurrentBlock;
    HFRange cacheLineCurrentBlockRange;
}
@property (nonatomic, retain) HFByteArray *byteArray;
@property (nonatomic, retain) NSMutableArray *lineCache;
- (NSAttributedString *)stringInByteRange:(HFRange)range;
- (HFRange)byteRangeForLineRange:(NSRange *)range;
- (HFRange)byteRangeForUTF8Range:(NSRange *)range;
- (unsigned long long)byteOffsetForUTF8Offset:(unsigned long long)offset;
- (unsigned long long)byteOffsetForUTF8Offset:(unsigned long long)offset inLineRange:(NSRange)lineRange line:(NSUInteger *)line;
- (BOOL)cacheLine;
@end

static const NSUInteger blockSize = 0x2000;

@implementation HexFiendDataSource

@synthesize file = _file;
@synthesize byteArray = _byteArray;
@synthesize lineCache = _lineCache;

- (void)setFile:(NSString *)file
{
    if (file == _file)
        return;
    [_file release];
    _file = [file retain];
    [self.lineCache removeAllObjects];
    self.byteArray = [[[HFBTreeByteArray alloc] init] autorelease];
    HFFileReference *fileReference = [[HFFileReference alloc] initWithPath:file error:NULL];
    HFFileByteSlice *byteSlice = [[HFFileByteSlice alloc] initWithFile:fileReference];
    [self.byteArray insertByteSlice:byteSlice inRange:HFRangeMake(0, 0)];
    [byteSlice release];
    [fileReference release];
}

- (void)dealloc {
    self.file = nil;
    self.byteArray = nil;
    self.lineCache = nil;
    free(cacheLineCurrentBlock);
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        self.lineCache = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

- (BOOL)cacheLine
{
    unsigned long long length = [self.byteArray length];
    if ([[[self.lineCache lastObject] objectAtIndex:0] unsignedLongLongValue] == length)
        return NO;
    if (cacheLineCurrentByteOffset >= length)
    {
        [self.lineCache addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:cacheLineCurrentByteOffset], [NSNumber numberWithUnsignedLongLong:cacheLineCurrentLineUTF8Offset], nil]];
        return YES;
    }
    if (!cacheLineCurrentBlock)
    {
        cacheLineCurrentBlockRange.location = 0;
        cacheLineCurrentBlockRange.length = MIN(blockSize, length);
        cacheLineCurrentBlock = malloc(cacheLineCurrentBlockRange.length);
        [self.byteArray copyBytes:cacheLineCurrentBlock range:cacheLineCurrentBlockRange];
    }
    while (cacheLineCurrentByteOffset < length)
    {
        if (cacheLineCurrentByteOffset >= cacheLineCurrentBlockRange.location + cacheLineCurrentBlockRange.length || cacheLineCurrentByteOffset < cacheLineCurrentBlockRange.location)
        {
            cacheLineCurrentBlockRange.location = cacheLineCurrentByteOffset;
            unsigned long long oldLength = cacheLineCurrentBlockRange.length;
            cacheLineCurrentBlockRange.length = MIN(blockSize, length - cacheLineCurrentByteOffset);
            if (cacheLineCurrentBlockRange.length != oldLength)
            {
                free(cacheLineCurrentBlock);
                cacheLineCurrentBlock = malloc(cacheLineCurrentBlockRange.length);
            }
            [self.byteArray copyBytes:cacheLineCurrentBlock range:cacheLineCurrentBlockRange];
        }
        unsigned char currentByte = cacheLineCurrentBlock[cacheLineCurrentByteOffset - cacheLineCurrentBlockRange.location];
        if (currentByte == '\n')
        {
            [self.lineCache addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:cacheLineCurrentLineByteOffset], [NSNumber numberWithUnsignedLongLong:cacheLineCurrentLineUTF8Offset], nil]];
            ++cacheLineCurrentByteOffset;
            ++cacheLineCurrentUTF8Offset;
            cacheLineCurrentLineByteOffset = cacheLineCurrentByteOffset;
            cacheLineCurrentLineUTF8Offset = cacheLineCurrentUTF8Offset;
            return YES;
        }
        if (currentByte >> 7 == 0)
            ++cacheLineCurrentByteOffset;
        else if (currentByte >> 5 == 0)
            cacheLineCurrentByteOffset += 2;
        else if (currentByte >> 4 == 0)
            cacheLineCurrentByteOffset += 3;
        else if (currentByte >> 3 == 0)
            cacheLineCurrentByteOffset += 4;
        ++cacheLineCurrentUTF8Offset;
    }
    [self.lineCache addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:cacheLineCurrentLineByteOffset], [NSNumber numberWithUnsignedLongLong:cacheLineCurrentLineUTF8Offset], nil]];
    return YES;
}

- (NSAttributedString *)stringInByteRange:(HFRange)range
{
    unsigned char *buffer = malloc(range.length * sizeof(unsigned char));
    [self.byteArray copyBytes:buffer range:range];
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:range.length freeWhenDone:YES];
    return [[[NSAttributedString alloc] initWithString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]] autorelease];
}

- (HFRange)byteRangeForLineRange:(NSRange *)range
{
    NSUInteger firstLineOutOfRange = range->location + range->length;
    if (firstLineOutOfRange >= [self.lineCache count])
    {
        NSUInteger line;
        for (line = [self.lineCache count]; line <= firstLineOutOfRange; ++line)
            if (![self cacheLine])
                break;
        firstLineOutOfRange = line - 1;
        range->length = firstLineOutOfRange - range->location;
    }
    NSLog(@"%@", self.lineCache);
    NSLog(@"%u", [self.lineCache count]);
    NSLog(@"firstLineOutOfRange: %u", firstLineOutOfRange);
    unsigned long long byteLocation = [[[self.lineCache objectAtIndex:range->location] objectAtIndex:0] unsignedLongLongValue];
    unsigned long long byteLength = [[[self.lineCache objectAtIndex:firstLineOutOfRange] objectAtIndex:0] unsignedLongLongValue] - byteLocation - 1;
    return HFRangeMake(byteLocation, byteLength);
}

- (HFRange)byteRangeForUTF8Range:(NSRange *)range
{
    unsigned long long firstCharacterOutOfRange = range->location + range->length;
    while (firstCharacterOutOfRange > [[[self.lineCache lastObject] objectAtIndex:1] unsignedLongLongValue])
        if (![self cacheLine])
        {
            range->length = [[[self.lineCache lastObject] objectAtIndex:1] unsignedLongLongValue] - range->location;
            firstCharacterOutOfRange = range->location + range->length;
        }
    unsigned long long byteLocation = [self byteOffsetForUTF8Offset:range->location];
    unsigned long long byteLength = [self byteOffsetForUTF8Offset:firstCharacterOutOfRange] - byteLocation;
    return HFRangeMake(byteLocation, byteLength);
}

- (unsigned long long)byteOffsetForUTF8Offset:(unsigned long long)offset
{
    return [self byteOffsetForUTF8Offset:offset inLineRange:NSMakeRange(0, [self.lineCache count]) line:NULL];
}

- (unsigned long long)byteOffsetForUTF8Offset:(unsigned long long)offset inLineRange:(NSRange)lineRange line:(NSUInteger *)line
{
    unsigned long long firstLineOffset = [[[self.lineCache objectAtIndex:lineRange.location] objectAtIndex:1] unsignedLongLongValue];
    if (offset < firstLineOffset)
        [NSException raise:NSInvalidArgumentException format:@"Invalid line range."];
    else if (offset == firstLineOffset)
    {
        if (line)
            *line = lineRange.location;
        return [[[self.lineCache objectAtIndex:lineRange.location] objectAtIndex:0] unsignedLongLongValue];
    }
    unsigned long long secondLineOffset = [[[self.lineCache objectAtIndex:lineRange.location + 1] objectAtIndex:1] unsignedLongLongValue];
    if ( secondLineOffset > offset)
    {
        if (line)
            *line = lineRange.location;
        unsigned long long currentByteOffset = [[[self.lineCache objectAtIndex:lineRange.location] objectAtIndex:0] unsignedLongLongValue];
        unsigned char *byte = malloc(sizeof(unsigned char));
        for (unsigned long long currentOffset = firstLineOffset; currentOffset < secondLineOffset; ++currentOffset)
        {
            if (currentOffset == offset)
                break;
            [self.byteArray copyBytes:byte range:HFRangeMake(currentByteOffset, 1)];
            if (*byte >> 7 == 0)
                ++currentByteOffset;
            else if (*byte >> 5 == 0)
                currentByteOffset += 2;
            else if (*byte >> 4 == 0)
                currentByteOffset += 3;
            else if (*byte >> 3 == 0)
                currentByteOffset += 4;
        }
        free(byte);
        return currentByteOffset;
    }
    unsigned long long halfCharOffset = [[[self.lineCache objectAtIndex:lineRange.location + lineRange.length / 2] objectAtIndex:1] unsignedLongLongValue];
    if (halfCharOffset > offset)
        lineRange = NSMakeRange(lineRange.location, lineRange.length / 2);
    else
        lineRange = NSMakeRange(lineRange.location + lineRange.length / 2, lineRange.length - lineRange.length / 2);
    return [self byteOffsetForUTF8Offset:offset inLineRange:lineRange line:line];
}

- (NSUInteger)textLength
{
    if (!self.file)
        return 0;
    return [self.byteArray length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    if (!self.file || !lineRange || !lineRange->length)
        return nil;
    NSUInteger oldLength = lineRange->length;
    NSAttributedString *string = [self stringInByteRange:[self byteRangeForLineRange:lineRange]];
    if (oldLength != lineRange->length)
        if (endOfString)
            *endOfString = YES;
    return string;
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    if (!self.file || !range.length)
        return nil;
    return [[self stringInByteRange:[self byteRangeForUTF8Range:&range]] string];
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    if (self.file)
        return YES;
    else
        return NO;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range
{
    if (!self.file)
        return;
    NSUInteger line = 0;
    [self byteOffsetForUTF8Offset:range.location inLineRange:NSMakeRange(0, [self.lineCache count]) line:&line];
    NSLog(@"inserting %@ at %u, %u", string, range.location, range.length);
    [self.byteArray insertByteSlice:[[HFSharedMemoryByteSlice alloc] initWithData:[NSMutableData dataWithData:[string dataUsingEncoding:NSUTF8StringEncoding]]] inRange:[self byteRangeForUTF8Range:&range]];
    NSUInteger lineCount = [self.lineCache count];
    for (; line + 1 < lineCount; ++line)
        [self.lineCache removeLastObject];
    cacheLineCurrentByteOffset = [[[self.lineCache lastObject] objectAtIndex:0] unsignedLongLongValue];
    cacheLineCurrentLineByteOffset = cacheLineCurrentByteOffset;
    cacheLineCurrentUTF8Offset = [[[self.lineCache lastObject] objectAtIndex:1] unsignedLongLongValue];
    cacheLineCurrentLineUTF8Offset = cacheLineCurrentUTF8Offset;
    [self.lineCache removeLastObject];
    [codeView updateAllText];
}

@end
