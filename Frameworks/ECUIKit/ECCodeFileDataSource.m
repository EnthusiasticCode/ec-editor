//
//  ECCodeFileDataSource.m
//  CodeView
//
//  Created by Nicola Peduzzi on 13/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeFileDataSource.h"


@interface ECCodeFileDataSource () {
@private
    NSFileHandle *fileHandle;
    unsigned long long fileLength;
    
    NSData *lineDelimiterData;
    NSMutableDictionary *lineOffsetsDictionary;
}

/// Returns the offset of the beginning of the given line in the file.
/// This methods uses lineDelimiterData to determin the end of a line
/// and caches line offsets in lineOffsetsDicionary;
- (unsigned long long)lineOffsetForLine:(NSUInteger *)line;

@end

@implementation ECCodeFileDataSource

#pragma mark Properties

@synthesize defaultTextStyle;
@synthesize chunkSize;
@synthesize path;

- (void)setPath:(NSString *)filePath
{
    [fileHandle release];
    [path release];
    
    path = [filePath retain];
    
    // Resetting file cursors
    fileHandle = [[NSFileHandle fileHandleForReadingAtPath:path] retain];
    [fileHandle seekToEndOfFile];
    fileLength = [fileHandle offsetInFile];
    [lineOffsetsDictionary removeAllObjects];
}

- (NSString *)lineDelimiter
{
    return lineDelimiterData ? [[[NSString alloc] initWithData:lineDelimiterData encoding:NSUTF8StringEncoding] autorelease] : nil; 
}

- (void)setLineDelimiter:(NSString *)lineDelimiter
{
    [lineDelimiterData release];
    lineDelimiterData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Initialization and Deallocation

- (id)init
{
    if ((self = [super init])) 
    {
        chunkSize = 10;
        defaultTextStyle = [[ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Inconsolata" size:15] color:nil] retain];
    }
    return self;
}

- (void)dealloc
{
    [lineOffsetsDictionary release];
    [lineDelimiterData release];
    [fileHandle release];
    [path release];
    [super dealloc];
}

#pragma mark CodeView Data Source Methods

- (NSUInteger)textLength
{
    return fileLength;
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    if (!fileHandle || range.location >= fileLength) 
        return nil;
    
    [fileHandle seekToFileOffset:range.location];
    NSData *stringData = [fileHandle readDataOfLength:range.length];
    return [[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding] autorelease];
}

// TODO editing methods

#pragma mark Text Renderer Data Source Methods

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    NSUInteger location = lineRange->location;
    unsigned long long lineRangeLocationOffset = [self lineOffsetForLine:&location];
    
    [fileHandle seekToFileOffset:lineRangeLocationOffset];
    if (location != lineRange->location)
        return nil;
    
    NSUInteger end = NSMaxRange(*lineRange);
    unsigned long long lineRangeEndOffset = [self lineOffsetForLine:&end];
    NSData *textData = [fileHandle readDataOfLength:(NSUInteger)(lineRangeEndOffset - lineRangeLocationOffset)];
    
    lineRange->length = end - location;
    NSString *string = [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding];
    NSAttributedString *result = [[NSAttributedString alloc] initWithString:string attributes:defaultTextStyle.CTAttributes];
    [string release];
    
    return [result autorelease];
}

#pragma mark Private Methods

- (unsigned long long)lineOffsetForLine:(NSUInteger *)line
{
    if (lineOffsetsDictionary)
        lineOffsetsDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSNumber *lineNumber = [NSNumber numberWithUnsignedInteger:*line];
    NSNumber *cachedOffset = [lineOffsetsDictionary objectForKey:lineNumber];
    if (cachedOffset) 
    {
        return [cachedOffset unsignedLongLongValue];
    }
    else
    {
        // Search for closest line key
        // TODO search for closest offset and proceed forward or backward to refine.
        NSNumber *closestKey = [NSNumber numberWithUnsignedInteger:0];
        for (NSNumber *key in lineOffsetsDictionary) 
        {
            if ([key compare:lineNumber] == NSOrderedAscending
                && [key compare:closestKey] == NSOrderedDescending)
            {
                closestKey = key;
            }
        }
        
        // Seek as closest as possible to required line
        NSUInteger lineCount = [closestKey unsignedIntegerValue];
        unsigned long long fileOffset = [[lineOffsetsDictionary objectForKey:closestKey] unsignedLongLongValue];
        [fileHandle seekToFileOffset:fileOffset];
        
        // Seek to line
        unsigned long long lineOffset = fileOffset;
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        while (lineCount <= *line && fileOffset < fileLength) 
        {
            NSData *chunk = [fileHandle readDataOfLength:chunkSize];
            NSUInteger chunkLength = [chunk length];
            NSRange newLineRange = [chunk rangeOfData:lineDelimiterData options:0 range:(NSRange){0, chunkLength}];
            if (newLineRange.location != NSNotFound) 
            {
                lineCount++;
                lineOffset = fileOffset + NSMaxRange(newLineRange);
            }
            fileOffset += chunkLength;
        }
        [pool drain];
        
        // TODO cache that every line after this are after eof?
        if (fileOffset >= fileLength)
            lineOffset = fileLength - 1;
        
        // Cache result
        [lineOffsetsDictionary setObject:lineNumber forKey:[NSNumber numberWithUnsignedLongLong:lineOffset]];
        
        *line = lineCount;
        return lineOffset;
    }
}

@end
