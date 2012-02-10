//
//  FileBuffer.m
//  Foundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FileBuffer.h"
#import "WeakDictionary.h"

static WeakDictionary *_fileBuffers;
static dispatch_queue_t _fileBuffersQueue;

@interface FileBuffer ()
{
    NSURL *_fileURL;
    dispatch_queue_t _fileAccessQueue;
    NSMutableArray *_consumers;
    NSMutableAttributedString *_contents;
}
@end

@implementation FileBuffer

+ (void)initialize
{
    if (self != [FileBuffer class])
        return;
    _fileBuffers = [[WeakDictionary alloc] init];
    _fileBuffersQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
}

+ (void)saveAllBuffers
{
    __block WeakDictionary *fileBuffers = nil;
    dispatch_sync(_fileBuffersQueue, ^{
        fileBuffers = _fileBuffers;
    });
    for (FileBuffer *fileBuffer in [fileBuffers objectEnumerator])
        [fileBuffer save];
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    __block FileBuffer *existingFileBuffer = nil;
    dispatch_sync(_fileBuffersQueue, ^{
        existingFileBuffer = [_fileBuffers objectForKey:fileURL];
    });
    if (existingFileBuffer)
        return existingFileBuffer;
    
    self = [super init];
    if (!self)
        return nil;
    _fileURL = fileURL;
    _fileAccessQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    _consumers = [[NSMutableArray alloc] init];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:fileURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
        _contents = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL]];
    }];
    if (!_contents)
        _contents = [[NSMutableAttributedString alloc] initWithString:@""];
    
    dispatch_barrier_sync(_fileBuffersQueue, ^{
        existingFileBuffer = [_fileBuffers objectForKey:fileURL];
        if (!existingFileBuffer)
            [_fileBuffers setObject:self forKey:fileURL];
    });
    if (existingFileBuffer)
        return existingFileBuffer;
    return self;
}

- (void)dealloc
{
    if (_fileAccessQueue)
        dispatch_release(_fileAccessQueue);
}

- (NSURL *)fileURL
{
    return _fileURL;
}

- (void)addConsumer:(id<FileBufferConsumer>)consumer
{
    dispatch_barrier_async(_fileAccessQueue, ^{
        ECASSERT([consumer conformsToProtocol:@protocol(FileBufferConsumer)]);
        [_consumers addObject:consumer];
    });
}

- (void)removeConsumer:(id<FileBufferConsumer>)consumer
{
    dispatch_barrier_sync(_fileAccessQueue, ^{
        ECASSERT([_consumers containsObject:consumer]);
        [_consumers removeObject:consumer];
    });
}

- (NSArray *)consumers
{
    __block NSArray *consumers = nil;
    dispatch_barrier_sync(_fileAccessQueue, ^{
        consumers = [_consumers copy];
    });
    return consumers;
}

- (NSUInteger)length
{
    __block NSUInteger length = 0;
    dispatch_sync(_fileAccessQueue, ^{
        length = [_contents length];
    });
    return length;
}

- (NSString *)stringInRange:(NSRange)range
{
    __block NSString *stringInRange = nil;
    dispatch_sync(_fileAccessQueue, ^{
        stringInRange = [[_contents string] substringWithRange:range];
    });
    return [stringInRange copy];
}

- (NSString *)string
{
    __block NSString *string = nil;
    dispatch_sync(_fileAccessQueue, ^{
        string = [_contents string];
    });
    return [string copy];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[self stringInRange:range]])
        return;
    dispatch_barrier_async(_fileAccessQueue, ^{
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string];
        if ([string length])
            [_contents replaceCharactersInRange:range withString:string];
        else
            [_contents deleteCharactersInRange:range];
        for (id<FileBufferConsumer> consumer in _consumers)
        {
            if ([consumer respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withString:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didReplaceCharactersInRange:range withString:string];
                }];
            if ([consumer respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withAttributedString:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didReplaceCharactersInRange:range withAttributedString:attributedString];
                }];
        }
    });
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    __block NSAttributedString *attributedStringInRange = nil;
    dispatch_sync(_fileAccessQueue, ^{
        attributedStringInRange = [_contents attributedSubstringFromRange:range];
    });
    return attributedStringInRange;
}

- (NSAttributedString *)attributedString
{
    __block NSAttributedString *attributedString = nil;
    dispatch_sync(_fileAccessQueue, ^{
        attributedString = [_contents copy];
    });
    return attributedString;
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![attributedString length])
        return;
    // replacing a substring with an equal string, no change required
    if ([attributedString isEqualToAttributedString:[self attributedStringInRange:range]])
        return;
    dispatch_barrier_async(_fileAccessQueue, ^{
        NSString *string = [attributedString string];
        if ([attributedString length])
            [_contents replaceCharactersInRange:range withAttributedString:attributedString];
        else
            [_contents deleteCharactersInRange:range];
        for (id<FileBufferConsumer> consumer in _consumers)
        {
            if ([consumer respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withAttributedString:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didReplaceCharactersInRange:range withAttributedString:attributedString];
                }];
            if ([consumer respondsToSelector:@selector(fileBuffer:didReplaceCharactersInRange:withString:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didReplaceCharactersInRange:range withString:string];
                }];
        }
    });
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    dispatch_barrier_async(_fileAccessQueue, ^{
        [_contents addAttributes:attributes range:range];
        for (id<FileBufferConsumer> consumer in _consumers)
            if ([consumer respondsToSelector:@selector(fileBuffer:didAddAttributes:range:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didAddAttributes:attributes range:range];
                }];
    });
}

- (void)removeAttributes:(NSArray *)attributeNames range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributeNames count] || !range.length)
        return;
    dispatch_barrier_async(_fileAccessQueue, ^{
        for (NSString *attributeName in attributeNames)
            [_contents removeAttribute:attributeName range:range];
        for (id<FileBufferConsumer> consumer in _consumers)
            if ([consumer respondsToSelector:@selector(fileBuffer:didRemoveAttributes:range:)])
                [[consumer consumerOperationQueue] addOperationWithBlock:^{
                    [consumer fileBuffer:self didRemoveAttributes:attributeNames range:range];
                }];
    });
}

- (id)attribute:(NSString *)attrName atIndex:(NSUInteger)location longestEffectiveRange:(NSRangePointer)range
{
    ECASSERT(location < [_contents length]);
    __block id attribute = nil;
    NSRange longestEffectiveRange = NSMakeRange(NSNotFound, 0);
    dispatch_sync(_fileAccessQueue, ^{
        attribute = [_contents attribute:attrName atIndex:location longestEffectiveRange:(NSRangePointer)&longestEffectiveRange inRange:NSMakeRange(0, [_contents length])];
    });
    if (range)
        *range = longestEffectiveRange;
    return attribute;
}

- (NSRange)lineRangeForRange:(NSRange)range
{
    __block NSRange lineRange;
    dispatch_sync(_fileAccessQueue, ^{
        lineRange = [[_contents string] lineRangeForRange:range];
    });
    return lineRange;
}

- (void)enumerateSubstringsInRange:(NSRange)range options:(NSStringEnumerationOptions)options usingBlock:(void (^)(NSString *, NSRange, NSRange, BOOL *))block
{
    ECASSERT(block);
    ECASSERT(!(options & NSStringEnumerationByWords) && !(options & NSStringEnumerationBySentences) && !(options & NSStringEnumerationLocalized) && !(options & NSStringEnumerationByComposedCharacterSequences));
    ECASSERT(!(options & NSStringEnumerationReverse));
    NSRange substringRange = NSMakeRange(range.location, 0);
    NSRange substringContentsRange;
    __block NSUInteger substringStart;
    __block NSUInteger substringEnd;
    __block NSUInteger substringContentsEnd;
    __block NSString *substring;
    BOOL stop = NO;
    for (;;)
    {
        if (substringRange.location >= NSMaxRange(range))
            break;
        if (options & NSStringEnumerationByLines)
            dispatch_sync(_fileAccessQueue, ^{
                [[_contents string] getLineStart:&substringStart end:&substringEnd contentsEnd:&substringContentsEnd forRange:substringRange];
            });
        else if (options & NSStringEnumerationByParagraphs)
            dispatch_sync(_fileAccessQueue, ^{
                [[_contents string] getParagraphStart:&substringStart end:&substringEnd contentsEnd:&substringContentsEnd forRange:substringRange];
            });
        else
            break;
        substringRange = NSMakeRange(substringStart, substringEnd - substringStart);
        substringContentsRange = NSMakeRange(substringStart, substringContentsEnd - substringStart);
        if (options & NSStringEnumerationSubstringNotRequired)
            substring = nil;
        else
            dispatch_sync(_fileAccessQueue, ^{
                substring = [[_contents string] substringWithRange:substringContentsRange];
            });
        
        block(substring, substringContentsRange, substringRange, &stop);
        if (stop)
            break;
        substringRange = NSMakeRange(NSMaxRange(substringRange), 0);
    }
}

- (NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT(regexp);
    __block NSUInteger numberOfMatches = 0;
    dispatch_sync(_fileAccessQueue, ^{
        numberOfMatches = [regexp numberOfMatchesInString:[_contents string] options:options range:range];
    });
    return numberOfMatches;
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT(regexp);
    __block NSArray *matches = nil;
    dispatch_sync(_fileAccessQueue, ^{
        matches = [regexp matchesInString:[_contents string] options:options range:range];
    });
    return matches;
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    ECASSERT(regexp);
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result offset:(NSInteger)offset template:(NSString *)replacementTemplate
{
    ECASSERT(result);
    __block NSString *replacementString = nil;
    dispatch_sync(_fileAccessQueue, ^{
        replacementString = [result.regularExpression replacementStringForResult:result inString:[_contents string] offset:offset template:replacementTemplate];
    });
    return replacementString;
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset
{
    ECASSERT(match && replacementTemplate);
    
    NSRange replacementRange = match.range;
    NSString *replacementString =  [self replacementStringForResult:match offset:offset template:replacementTemplate];
    
    replacementRange.location += offset;
    [self replaceCharactersInRange:replacementRange withString:replacementString];
    replacementRange.length = replacementString.length;
    
    return replacementRange;
}

- (void)save
{
    dispatch_sync(_fileAccessQueue, ^{
        [[_contents string] writeToURL:self.fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    });
}

@end
