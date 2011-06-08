//
//  ECCodeFileDataSource.m
//  CodeView
//
//  Created by Nicola Peduzzi on 13/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeFileDataSource.h"
#import "NSData+UTF8.h"


@interface ECCodeFileDataSource () {
@private
    NSFileHandle *fileHandle;
    unsigned long long fileLength;
    
    NSData *lineDelimiterData;
    NSMutableDictionary *lineOffsetsDictionary;
    
    NSMutableAttributedString *editableString;
    struct {
        struct {
            unsigned long long location, lenght;
        } fileRange;
        BOOL dirty;
    } editable;
}

/// Returns the offset of the beginning of the given line in the file.
/// This methods uses lineDelimiterData to determin the end of a line
/// and caches line offsets in lineOffsetsDicionary;
- (unsigned long long)lineOffsetForLine:(NSUInteger *)line;

- (void)openInputFile;

@end

@implementation ECCodeFileDataSource

#pragma mark Properties

@synthesize defaultTextStyle;
@synthesize stylizeBlock;
@synthesize chunkSize;
@synthesize inputFileURL;

- (void)setInputFileURL:(NSURL *)inputURL
{
    fileHandle = nil;
    inputFileURL = inputURL;
    
    [self openInputFile];
}

- (NSString *)lineDelimiter
{
    return lineDelimiterData ? [[NSString alloc] initWithData:lineDelimiterData encoding:NSUTF8StringEncoding] : nil; 
}

- (void)setLineDelimiter:(NSString *)lineDelimiter
{
    lineDelimiterData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Initialization and Deallocation

- (id)init
{
    if ((self = [super init])) 
    {
        chunkSize = 1024;
        self.lineDelimiter = @"\n";
        self.defaultTextStyle = [ECTextStyle textStyleWithName:@"default" font:[UIFont fontWithName:@"Inconsolata" size:15] color:nil];
    }
    return self;
}

- (void)dealloc
{
    [self flush];
}

#pragma mark Public Methods

- (void)flush
{
    if (!editable.dirty)
        return;
    
    NSURL *tempFileURL = [[NSURL URLWithString:NSTemporaryDirectory()] URLByAppendingPathComponent:[inputFileURL lastPathComponent]];
    @autoreleasepool
    {
        // Get temporary file
        NSFileHandle *tempFile = [NSFileHandle fileHandleForWritingToURL:tempFileURL error:NULL];
        
        // Writing data
        // TODO see if pool should be moved inside loop
        NSData *writeData;
        NSUInteger writeDataSize;
        unsigned long long writeBytesCount = editable.fileRange.location;
        [fileHandle seekToFileOffset:0];
        // Head
        while (writeBytesCount) 
        {
            writeDataSize = MIN((NSUInteger)writeBytesCount, chunkSize);
            writeData = [fileHandle readDataOfLength:writeDataSize];
            [tempFile writeData:writeData];
            writeBytesCount -= writeDataSize;
        }
        // Changed
        writeData = [[editableString string] dataUsingEncoding:NSUTF8StringEncoding];
        [tempFile writeData:writeData];
        writeBytesCount = fileLength - (editable.fileRange.location + editable.fileRange.lenght);
        editable.fileRange.lenght = [writeData length];
        // Tail
        while (writeBytesCount) 
        {
            writeDataSize = MIN((NSUInteger)writeBytesCount, chunkSize);
            writeData = [fileHandle readDataOfLength:writeDataSize];
            [tempFile writeData:writeData];
            writeBytesCount -= writeDataSize;
        }
    }
    
    // Move file into position
//    [tempFile closeFile];
    [[NSFileManager defaultManager] moveItemAtURL:tempFileURL toURL:inputFileURL error:NULL];
    [self openInputFile];
    
    editable.dirty = NO;
}

#pragma mark CodeView Data Source Methods

- (NSUInteger)textLength
{
    return (NSUInteger)fileLength;
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    if (!fileHandle || range.location >= fileLength) 
        return nil;
    
    [fileHandle seekToFileOffset:range.location];
    NSData *stringData = [fileHandle readDataOfLength:range.length];
    return [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range
{
    
}

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
    [self flush];
    lineRange->length = end - location;
    NSString *string = [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding];
    editableString = [[NSMutableAttributedString alloc] initWithString:string attributes:defaultTextStyle.CTAttributes];
    editable.fileRange.location = lineRangeLocationOffset;
    editable.fileRange.lenght = lineRangeEndOffset - lineRangeLocationOffset;
    
    // Apply custom styles
    if (stylizeBlock)
        stylizeBlock(self, editableString, NSMakeRange((NSUInteger)lineRangeLocationOffset, (NSUInteger)(editable.fileRange.lenght)));
    
    // Determine end of file/string and append tailing new line
    if ([fileHandle offsetInFile] >= fileLength)
    {
        NSAttributedString *lineDelimiter = [[NSAttributedString alloc] initWithString:self.lineDelimiter attributes:defaultTextStyle.CTAttributes];
        [editableString appendAttributedString:lineDelimiter];
        
        if (endOfString)
            *endOfString = YES;
    }
    
    return editableString;
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    // TODO implement this metohd? or remove completelly the need of it, useless: the renderer resize itself anyway.
    return (NSUInteger)fileLength / maximumLineLength;
}

#pragma mark Private Methods

- (void)openInputFile
{
    fileHandle = [NSFileHandle fileHandleForReadingFromURL:inputFileURL error:NULL];
    [fileHandle seekToEndOfFile];
    fileLength = [fileHandle offsetInFile];
    
    if (!lineOffsetsDictionary)
        lineOffsetsDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    else
        [lineOffsetsDictionary removeAllObjects];
    [lineOffsetsDictionary setObject:[NSNumber numberWithUnsignedLongLong:0] forKey:[NSNumber numberWithUnsignedInteger:0]];
}

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
        NSNumber *closestOffset = [lineOffsetsDictionary objectForKey:closestKey];
        unsigned long long fileOffset = [closestOffset unsignedLongLongValue];
        [fileHandle seekToFileOffset:fileOffset];
        
        // Seek to line
        unsigned long long lineOffset = fileOffset;
        @autoreleasepool
        {
            NSRange newLineRange;
            NSData *chunk;
            NSUInteger chunkLength = 0;
            while (lineCount < *line && fileOffset < fileLength) 
            {
                fileOffset += chunkLength;
                
                chunk = [fileHandle readDataOfLength:chunkSize];
                chunkLength = [chunk length];
                
                newLineRange.location = 0;
                newLineRange.length = chunkLength;
                while (newLineRange.length && (newLineRange = [chunk rangeOfData:lineDelimiterData options:0 range:newLineRange]).location != NSNotFound) 
                {
                    lineCount++;
                    lineOffset = fileOffset + newLineRange.location;
                    
                    if (lineCount >= *line)
                        break;
                    
                    newLineRange.location += newLineRange.length;
                    newLineRange.length = chunkLength - newLineRange.location;
                }
            }
        }
        
        // TODO cache that every line after this are after eof?
        // Adding last line of file
        if (fileOffset >= fileLength && lineOffset < fileLength)
        {
            lineOffset = fileLength;
            lineCount++;
        }
        
        // Cache result
        cachedOffset = [NSNumber numberWithUnsignedLongLong:lineOffset];
        [lineOffsetsDictionary setObject:cachedOffset forKey:lineNumber];
        
        *line = lineCount;
        return lineOffset;
    }
}

@end
