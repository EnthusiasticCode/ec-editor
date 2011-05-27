//
//  ECCodeByteArrayDataSource.m
//  CodeView
//
//  Created by Nicola Peduzzi on 22/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeByteArrayDataSource.h"

#import "ECCodeViewBase.h"
#import "ECTextStyle.h"

#import "HFFunctions.h"
#import "HFBTreeByteArray.h"
#import "HFSharedMemoryByteSlice.h"
#import "HFFileByteSlice.h"
#import "HFFileReference.h"

#import "NSData+UTF8.h"

#pragma mark Offset Cache Element

@interface FileTriOffset : NSObject <NSCopying>

@property (nonatomic) NSUInteger line;
@property (nonatomic) NSUInteger character;
@property (nonatomic) unsigned long long byte;

+ (id)fileOffsetWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b;

- (id)initWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b;
- (id)fileOffsetByAddingLines:(NSInteger)l characters:(NSInteger)c bytes:(long long)b;
@end

@implementation FileTriOffset

@synthesize line, character, byte;

+ (id)fileOffsetWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b
{
    return [[[self alloc] initWithLine:l character:c byte:b] autorelease];
}

- (id)initWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b
{
    if ((self = [super init])) 
    {
        line = l;
        character = c;
        byte = b;
    }
    return self;
}

- (id)fileOffsetByAddingLines:(NSInteger)l characters:(NSInteger)c bytes:(long long)b
{
    return [[[FileTriOffset alloc] initWithLine:(line + l) character:(character + c) byte:(byte + b)] autorelease];
}

// TODO delete all this unused methods
- (id)copyWithZone:(NSZone *)zone
{
    return [[FileTriOffset allocWithZone:zone] initWithLine:line character:character byte:byte];
}

- (NSUInteger)hash
{
    return line;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[FileTriOffset class]])
        return NO;
    
    FileTriOffset *offset = (FileTriOffset *)object;
    return offset.line == line && offset.character == character && offset.byte == byte;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"offset line:%u char:%u byte:%u", line, character, byte];
}

@end

#pragma mark -
#pragma mark Data Source Implementation

@interface ECCodeByteArrayDataSource () {
@private
    HFByteArray *byteArray;
    
    NSMutableArray *offsetCache;
    FileTriOffset *eofOffset;
    
    struct {
        // Offset before and after the last committed position
        FileTriOffset *prevOffset, *nextOffset;
    } lastEdited;
    
    NSMutableData *editData;
}

/// Returns the offset of the beginning of the given line in the file.
/// This methods uses lineDelimiter to determin the end of a line
/// and caches line offsets in offsetCache;
- (FileTriOffset *)offsetForLine:(NSUInteger)line;

- (FileTriOffset *)offsetForCharacter:(NSUInteger)character;

@end

@implementation ECCodeByteArrayDataSource

#pragma mark Properties

@synthesize fileURL, lineDelimiter, chunkSize;
@synthesize defaultTextStyle, stylizeBlock;


- (void)setFileURL:(NSURL *)url
{
    [self writeToFile];
    
    [fileURL release];
    fileURL = [url retain];
    
    [byteArray release];
    byteArray = [HFBTreeByteArray new];
    
    // Read the file
    // TODO manage error
    HFFileReference *fileReference = [[HFFileReference alloc] initWritableWithPath:[fileURL path] error:NULL];
    HFFileByteSlice *fileByteSlice = [[HFFileByteSlice alloc] initWithFile:fileReference];
    [byteArray insertByteSlice:fileByteSlice inRange:(HFRange){0, 0}];
    [fileByteSlice release];
    [fileReference release];
    
    // Flush caches
    if (!offsetCache)
        offsetCache = [NSMutableArray new];
    else
        [offsetCache removeAllObjects];
    [offsetCache addObject:[FileTriOffset fileOffsetWithLine:0 character:0 byte:0]];
    eofOffset = nil;
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
    [self writeToFile];
    
    [byteArray release];
    [offsetCache release];
    
    [lastEdited.prevOffset release];
    [lastEdited.nextOffset release];
    [editData release];
    
    [fileURL release];
    [lineDelimiter release];
    [defaultTextStyle release];
    [stylizeBlock release];
    
    [super dealloc];
}

#pragma mark Public Methods

- (void)writeToFile
{
    // TODO manage edit data, release
    // TODO manage progress tracking and errors
    if (fileURL)
        [byteArray writeToFile:fileURL trackingProgress:nil error:NULL];
}

#pragma mark CodeView Data Source Methods

- (NSUInteger)textLength
{
    return eofOffset ? eofOffset.character : [byteArray length];
}

- (NSString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range
{
    if (!fileURL)
        return nil;
    
    FileTriOffset *startOffset = [self offsetForCharacter:range.location];
    FileTriOffset *endOffset = [self offsetForCharacter:NSMaxRange(range)];
    HFRange fileRange = HFRangeMake(startOffset.byte, endOffset.byte - startOffset.byte);
    
    char *stringBuffer = (char *)malloc(fileRange.length);
    [byteArray copyBytes:(unsigned char *)stringBuffer range:fileRange];
    
    NSString *result = [[NSString alloc] initWithBytesNoCopy:stringBuffer length:fileRange.length encoding:NSUTF8StringEncoding freeWhenDone:YES];
    if (!result)
        free(stringBuffer);
    
    return [result autorelease];
}

- (BOOL)codeView:(ECCodeViewBase *)codeView canEditTextInRange:(NSRange)range
{
    return YES;
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)string forTextInRange:(NSRange)range
{
    if (!fileURL)
        return;
    
    // Cached subsequent edit check
    FileTriOffset *startOffset;
    if (lastEdited.nextOffset && lastEdited.nextOffset.character == range.location)
    {
        startOffset = lastEdited.nextOffset;
    }
    else if (lastEdited.prevOffset && lastEdited.prevOffset.character == range.location)
    {
        startOffset = lastEdited.prevOffset;
    }
    else
    {
        startOffset = [self offsetForCharacter:range.location];
    }
    
    // Fast way to detect editing in position
    NSUInteger rangeEnd = NSMaxRange(range);
    FileTriOffset *endOffset;
    if (startOffset.character == rangeEnd)
    {
        endOffset = startOffset;
    }
    else if (lastEdited.nextOffset && lastEdited.nextOffset.character == rangeEnd)
    {
        endOffset = lastEdited.nextOffset;
    }
    else
    {
        endOffset = [self offsetForCharacter:rangeEnd];
    }
    
    // Edit deltas
    NSInteger fromCharacterCount = (NSInteger)(endOffset.character - startOffset.character);
    NSInteger fromByteCount = (NSInteger)(endOffset.byte - startOffset.byte);
    NSRange fromLineRange = NSMakeRange(startOffset.line, endOffset.line - startOffset.line + 1);
    NSRange toLineRange = NSMakeRange(startOffset.line, 1);
    
    // Edit string informations
    NSData *stringData = nil;
    NSUInteger stringDataLength = 0;
    NSUInteger stringLenght = [string length];
    // Edited range in bytes
    HFRange fileRange = HFRangeMake(startOffset.byte, endOffset.byte - startOffset.byte);
    if (stringLenght != 0)
    {
        // Get data to enter
        stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
        stringDataLength = [stringData length];
        if (!editData) 
            editData = [[NSMutableData dataWithCapacity:stringDataLength] retain];

        // Adding string to mutable data
        NSUInteger lastEditedDataOffset = [editData length];
        [editData appendData:stringData];
        
        // Insert slice with proper offset
        HFSharedMemoryByteSlice *slice = [[HFSharedMemoryByteSlice alloc] initWithData:editData offset:lastEditedDataOffset length:stringDataLength];
        [byteArray insertByteSlice:slice inRange:fileRange];
        [slice release];

        // Set proper toLineRange
        toLineRange.length = [stringData UTF8LineCountUsingLineDelimiter:lineDelimiter];
        
        // Cacheing offsets
        // TODO !!! validate this in limit cases when new offset line may be wrong
        // limit case when writing a char at the beginning of a line, the nextoffset will have wrong line number
        if (startOffset != lastEdited.nextOffset) 
        {
            [lastEdited.nextOffset release];
            lastEdited.nextOffset = [startOffset copy];
        }
        [lastEdited.prevOffset release];
        lastEdited.prevOffset = lastEdited.nextOffset;
        lastEdited.nextOffset = [[startOffset fileOffsetByAddingLines:(toLineRange.length - 1) 
                                                           characters:stringLenght 
                                                                bytes:stringDataLength] retain];
    }
    else // delete
    {
        [byteArray deleteBytesInRange:fileRange];
        
        if (startOffset.line != endOffset.line) 
        {
            [lastEdited.prevOffset release];
            lastEdited.prevOffset = nil;
            [lastEdited.nextOffset release];
            lastEdited.nextOffset = nil;
        }
        else
        {
            if (startOffset != lastEdited.prevOffset) 
            {
                [lastEdited.prevOffset release];
                lastEdited.prevOffset = [startOffset copy];
            }
            [lastEdited.nextOffset release];
            lastEdited.nextOffset = lastEdited.prevOffset;
            lastEdited.prevOffset = [[startOffset fileOffsetByAddingLines:0 
                                                               characters:-1
                                                                    bytes:-1] retain];
        }
    }
    
//    NSLog(@"\nprev %@, \nnext %@\n", lastEdited.prevOffset, lastEdited.nextOffset);
    
    // Update eof offset
    if (eofOffset)
    {
        eofOffset.line -= (NSInteger)(fromLineRange.length) - (NSInteger)(toLineRange.length);
        eofOffset.character -= fromCharacterCount - (NSInteger)(stringLenght);
        eofOffset.byte -= fromByteCount - (NSInteger)(stringDataLength);
    }
 
    [codeView updateTextInLineRange:fromLineRange toLineRange:toLineRange];
}

#pragma mark Text Renderer Data Source Methods

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString
{
    if (!fileURL)
        return nil;
    
    FileTriOffset *startOffset = [self offsetForLine:lineRange->location];
    if (startOffset.line != lineRange->location)
        return nil;
    
    FileTriOffset *endOffset = [self offsetForLine:NSMaxRange(*lineRange)];
    
    // Read and generate string from file
    NSUInteger stringByteLenght = endOffset.byte - startOffset.byte;
    char *stringByteBuffer = (char *)malloc(stringByteLenght);
    [byteArray copyBytes:(unsigned char *)stringByteBuffer range:(HFRange){ startOffset.byte, stringByteLenght }];
    NSString *string = [[NSString alloc] initWithBytesNoCopy:stringByteBuffer length:stringByteLenght encoding:NSUTF8StringEncoding freeWhenDone:YES];
    if (!string) 
    {
        free(stringByteBuffer);
        return nil;
    }
    
    // Stylize string
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:string attributes:defaultTextStyle.CTAttributes];
    [string release];
    
    if (stylizeBlock)
        stylizeBlock(self, resultString, NSMakeRange(startOffset.character, endOffset.character - startOffset.character));
    
    // Add additional line at the end of file
    if (endOffset == eofOffset) 
    {
        if (endOfString)
            *endOfString = YES;
        
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:lineDelimiter attributes:defaultTextStyle.CTAttributes];
        [resultString appendAttributedString:newLine];
        [newLine release];
    }
    
    return [resultString autorelease];
}

- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength
{
    // TODO ???
    return 0;
}

#pragma mark Private Methods

- (FileTriOffset *)offsetForLine:(NSUInteger)line
{
    // Check for end of file
    if (eofOffset && line >= eofOffset.line) 
        return eofOffset;
    
    // Cache search
    NSUInteger cachedIndex = [offsetCache indexOfObjectPassingTest:^BOOL(FileTriOffset *offset, NSUInteger idx, BOOL *stop) {
        return offset.line == line;
    }];
    if (cachedIndex != NSNotFound) 
        return [offsetCache objectAtIndex:cachedIndex];
    
    // Search for closest match
    __block NSUInteger closestIndex = NSNotFound;
    [offsetCache enumerateObjectsUsingBlock:^(FileTriOffset *offset, NSUInteger idx, BOOL *stop) {
        if (offset.line > line) 
            *stop = YES;
        else
            closestIndex = idx;
    }];
    FileTriOffset *closestOffset = nil;
    if (closestIndex != NSNotFound)
        closestOffset = [offsetCache objectAtIndex:closestIndex];
    
    // Results
    NSUInteger resultLine = closestOffset.line;
    NSUInteger resultCharacter = closestOffset.character;
    unsigned long long resultByte = closestOffset.byte;
    // Chunk
    unsigned long long fileLength = [byteArray length];
    unsigned long long fileOffset = resultByte;
    char *chunk = (char *)malloc(chunkSize + 1);
    chunk[0] = 0;
    char *chunkLineStart = chunk;
    // Chunk range
    HFRange fileRange = (HFRange){0, 0};
    // Delimiter
    const char *delimiter = [lineDelimiter UTF8String];
    NSUInteger delimiterLenght = [lineDelimiter lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    // Seek to line
    while (resultLine < line && fileOffset < fileLength) 
    {
        // Update UTF8 offset
        resultCharacter += mbstowcs(NULL, chunk, chunkSize);
        // Read new chunk
        resultByte += fileRange.length;
        fileRange = HFRangeMake(resultByte, MIN(chunkSize, fileLength - resultByte));
        [byteArray copyBytes:(unsigned char *)chunk range:fileRange];
        chunk[fileRange.length] = 0;
        // Check for lines in chunk
        chunkLineStart = chunk;
        while(chunkLineStart - chunk < fileRange.length 
              && (chunkLineStart = strstr(chunkLineStart, delimiter)) != NULL)
        {
            resultLine++;
            chunkLineStart += delimiterLenght;
            if (resultLine >= line)
                break;
        }
        fileOffset += fileRange.length;
    }
    // Add last offet
    if (!chunkLineStart)
    {
        resultLine++;
        chunkLineStart = chunk + MIN(chunkSize, fileLength - resultByte);
    }
    *chunkLineStart = 0;
    resultCharacter += mbstowcs(NULL, chunk, chunkSize);
    resultByte += chunkLineStart - chunk;
    free(chunk);
    
    // Generate and cache result obect
    FileTriOffset *resultOffset = [FileTriOffset fileOffsetWithLine:resultLine character:resultCharacter byte:resultByte];
    [offsetCache insertObject:resultOffset atIndex:(closestIndex == NSNotFound ? 0 : closestIndex + 1)];
    
    // Check for EOF
    if (resultByte >= fileLength) 
        eofOffset = resultOffset;
    
    return resultOffset;
}

// TODO reduce code duplication
- (FileTriOffset *)offsetForCharacter:(NSUInteger)character
{
    // TODO handle special case of cacheing, cache last and next
    
    // Check for end of file
    if (eofOffset && character >= eofOffset.character)
        return eofOffset;
    
    // Cache search
    NSUInteger cachedIndex = [offsetCache indexOfObjectPassingTest:^BOOL(FileTriOffset *offset, NSUInteger idx, BOOL *stop) {
        return offset.character == character;
    }];
    if (cachedIndex != NSNotFound) 
        return [offsetCache objectAtIndex:cachedIndex];
    
    // Search for closest match
    __block NSUInteger closestIndex = NSNotFound;
    [offsetCache enumerateObjectsUsingBlock:^(FileTriOffset *offset, NSUInteger idx, BOOL *stop) {
        if (offset.character > character) 
            *stop = YES;
        else
            closestIndex = idx;
    }];
    FileTriOffset *closestOffset = nil;
    if (closestIndex != NSNotFound)
        closestOffset = [offsetCache objectAtIndex:closestIndex];
    
    // Results
    NSUInteger resultLine = closestOffset.line;
    NSUInteger resultCharacter = closestOffset.character;
    unsigned long long resultByte = closestOffset.byte;
    // Chunk
    unsigned long long fileLength = [byteArray length];
    unsigned long long fileOffset = resultByte;
    NSUInteger characterOffset = resultCharacter;
    NSUInteger lineLenght;
    char *chunk = (char *)malloc(chunkSize + 1);
    chunk[0] = 0;
    char *chunkLineStart = chunk, *chunkLineEnd = NULL;
    char chunkSwap;
    // Chunk range
    HFRange fileRange = (HFRange){0, 0};
    // Delimiter
    const char *delimiter = [lineDelimiter UTF8String];
    NSUInteger delimiterLenght = [lineDelimiter lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    // Seek to character
    while (characterOffset < character && fileOffset < fileLength) 
    {
        resultCharacter = characterOffset;
        // Read new chunk
        resultByte += fileRange.length;
        fileRange = HFRangeMake(resultByte, MIN(chunkSize, fileLength - resultByte));
        [byteArray copyBytes:(unsigned char *)chunk range:fileRange];
        chunk[fileRange.length] = 0;
        // Check for lines in chunk
        chunkLineStart = chunk;
        while(chunkLineStart - chunk < fileRange.length 
              && (chunkLineEnd = strstr(chunkLineStart, delimiter)) != NULL)
        {
            chunkLineEnd += delimiterLenght;
            chunkSwap = *chunkLineEnd;
            *chunkLineEnd = 0;
            lineLenght = mbstowcs(NULL, chunkLineStart, 0);
            *chunkLineEnd = chunkSwap;
            // Inside the correct line, seeking to requested character
            if (resultCharacter + lineLenght >= character)
            {
                // Moving to character
                while (resultCharacter < character) 
                {
                    do {
                        chunkLineStart++;
                    } while (*chunkLineStart >= 0x80);
                    resultCharacter++;
                }
                // Adding bytes, chunkLineStart has been moved just after the required character
                resultByte += chunkLineStart - chunk;
                break;
            }
            resultLine++;
            chunkLineStart = chunkLineEnd;
            resultCharacter += lineLenght;
        }
        // Update offsets
        characterOffset += mbstowcs(NULL, chunk, chunkSize);
        fileOffset += fileRange.length;
    }
    
    // Add last offet for missing tailing new line
    if (!chunkLineEnd)
    {
        lineLenght = mbstowcs(NULL, chunkLineStart, 0);
        if (resultCharacter + lineLenght >= character) 
        {
            while (resultCharacter < character) 
            {
                do {
                    chunkLineStart++;
                } while (*chunkLineStart >= 0x80);
                resultCharacter++;
            }
            resultByte += chunkLineStart - chunk;
        }
        else
        {
            // TODO!!! bug, if proceeding from a cached line in the same line (but different char) this line will add an unexisting line
            resultLine++;
            chunkLineEnd = chunk + MIN(chunkSize, fileLength - resultByte);
            resultByte += chunkLineEnd - chunk;
        }
    }
    free(chunk);
    
    // Generate and cache result obect
    FileTriOffset *resultOffset = [FileTriOffset fileOffsetWithLine:resultLine character:resultCharacter byte:resultByte];
    //[offsetCache insertObject:resultOffset atIndex:(closestIndex == NSNotFound ? 0 : closestIndex + 1)];
    
    // Check for EOF
//    if (resultByte >= fileLength) 
//        eofOffset = resultOffset;
    
    return resultOffset;
}

@end
