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
@synthesize stylizeBlock;
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
    
    if (!lineOffsetsDictionary)
        lineOffsetsDictionary = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
    else
        [lineOffsetsDictionary removeAllObjects];
    [lineOffsetsDictionary setObject:[NSNumber numberWithUnsignedLongLong:0] forKey:[NSNumber numberWithUnsignedInteger:0]];
}

- (NSString *)lineDelimiter
{
    return lineDelimiterData ? [[[NSString alloc] initWithData:lineDelimiterData encoding:NSUTF8StringEncoding] autorelease] : nil; 
}

- (void)setLineDelimiter:(NSString *)lineDelimiter
{
    [lineDelimiterData release];
    lineDelimiterData = [[lineDelimiter dataUsingEncoding:NSUTF8StringEncoding] retain];
}

#pragma mark Initialization and Deallocation

- (id)init
{
    if ((self = [super init])) 
    {
        chunkSize = 10;
        self.lineDelimiter = @"\n";
        self.defaultTextStyle = [ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Inconsolata" size:15] color:nil];
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
    // Position file at the beginning of the requested line range
    NSUInteger location = lineRange->location;
    unsigned long long lineRangeLocationOffset = [self lineOffsetForLine:&location];
    if (location != lineRange->location)
        return nil;
    
    // Get the last readable line
    NSUInteger end = NSMaxRange(*lineRange);
    unsigned long long lineRangeEndOffset = [self lineOffsetForLine:&end];
    
    // Read requested data from file
    [fileHandle seekToFileOffset:lineRangeLocationOffset];
    NSData *textData = [fileHandle readDataOfLength:(NSUInteger)(lineRangeEndOffset - lineRangeLocationOffset)];

    // Prepare return
    lineRange->length = end - location;
    NSString *string = [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding];    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:string attributes:defaultTextStyle.CTAttributes];
    [string release];
    
    // Apply custom styles
    if (stylizeBlock)
        stylizeBlock(self, result, NSMakeRange(lineRangeLocationOffset, (NSUInteger)(lineRangeEndOffset - lineRangeLocationOffset)));
    
    // Determine end of file/string and append tailing new line
    unsigned long long fileOffset = [fileHandle offsetInFile];
    if (fileOffset >= fileLength)
    {
        NSAttributedString *lineDelimiter = [[NSAttributedString alloc] initWithString:self.lineDelimiter attributes:defaultTextStyle.CTAttributes];
        [result appendAttributedString:lineDelimiter];
        [lineDelimiter release];
        
        if (endOfString)
            *endOfString = YES;
    }
    
    return [result autorelease];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    // TODO implement this metohd? or remove completelly the need of it, useless: the renderer resize itself anyway.
    return fileLength / maximumLineLength;
}

#pragma mark Private Methods

- (unsigned long long)lineOffsetForLine:(NSUInteger *)line
{
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
        NSData *chunk;
        NSUInteger chunkLength;
        NSRange newLineRange;
        while (lineCount < *line && fileOffset < fileLength) 
        {
            chunk = [fileHandle readDataOfLength:chunkSize];
            chunkLength = [chunk length];
            
            newLineRange.location = 0;
            newLineRange.length = chunkLength;
            while (newLineRange.length && (newLineRange = [chunk rangeOfData:lineDelimiterData options:0 range:newLineRange]).location != NSNotFound) 
            {
                lineCount++;
                lineOffset = fileOffset + NSMaxRange(newLineRange);
                
                newLineRange.location++;
                newLineRange.length = chunkLength - newLineRange.location;
            }
            
            fileOffset += chunkLength;
        }
        [pool drain];
        
        // TODO cache that every line after this are after eof?
        // Adding last line of file
        if (fileOffset >= fileLength && lineOffset < fileLength)
        {
            lineOffset = fileLength;
            lineCount++;
        }
        
        // Cache result
        [lineOffsetsDictionary setObject:[NSNumber numberWithUnsignedLongLong:lineOffset] forKey:lineNumber];
        
        *line = lineCount;
        return lineOffset;
    }
}

@end
