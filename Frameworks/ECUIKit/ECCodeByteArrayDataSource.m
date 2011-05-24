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

#pragma mark Offset Cache Element

@interface FileTriOffset : NSObject <NSCopying>

@property (nonatomic) NSUInteger line;
@property (nonatomic) NSUInteger character;
@property (nonatomic) unsigned long long byte;

+ (id)fileOffsetWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b;

@end

@implementation FileTriOffset

@synthesize line, character, byte;

+ (id)fileOffsetWithLine:(NSUInteger)l character:(NSUInteger)c byte:(unsigned long long)b
{
    FileTriOffset *result = [self new];
    result.line = l;
    result.character = c;
    result.byte = b;
    return [result autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[FileTriOffset allocWithZone:zone] init];
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

@end

#pragma mark -
#pragma mark Data Source Implementation

@interface ECCodeByteArrayDataSource () {
@private
    HFByteArray *byteArray;
    
    NSMutableArray *offsetCache;
    FileTriOffset *eofOffset;
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
    
    [fileURL release];
    [lineDelimiter release];
    [defaultTextStyle release];
    [stylizeBlock release];
    
    [super dealloc];
}

#pragma mark Public Methods

- (void)writeToFile
{
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
    
    // TODO cache subsequent calls to subsequent caracters
    FileTriOffset *startOffset = [self offsetForCharacter:range.location];
    FileTriOffset *endOffset = [self offsetForCharacter:NSMaxRange(range)];
    HFRange fileRange = HFRangeMake(startOffset.byte, endOffset.byte - startOffset.byte);
    
    // TODO save undo?
    NSData *stringData = nil;
    NSRange fromLineRange = NSMakeRange(startOffset.line, endOffset.line - startOffset.line + 1);
    NSRange toLineRange = NSMakeRange(startOffset.line, 1);
    if (!string || [string length] == 0) 
    {
        [byteArray deleteBytesInRange:fileRange];
    }
    else
    {
        // TODO buffer subsequent changes, commit to byteslice only when changeing in a different location
        stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
        HFSharedMemoryByteSlice *slice = [[HFSharedMemoryByteSlice alloc] initWithUnsharedData:stringData];
        [byteArray insertByteSlice:slice inRange:fileRange];
        [slice release];
        
        // TODO set proper toLineRange
    }
    
    // Update eof offset
    if (eofOffset)
    {
        eofOffset.line -= (NSInteger)(fromLineRange.length) - (NSInteger)(toLineRange.length);
        eofOffset.character -= (NSInteger)(endOffset.character - startOffset.character) - (NSInteger)([string length]);
        eofOffset.byte -= (NSInteger)(endOffset.byte - startOffset.byte) - (NSInteger)([stringData length]);
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
        // Update UTF8 offset
        characterOffset += mbstowcs(NULL, chunk, chunkSize);
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
