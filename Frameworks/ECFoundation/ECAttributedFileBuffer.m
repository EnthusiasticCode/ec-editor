//
//  ECAttributedFileBuffer.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECAttributedFileBuffer.h"
#import "ECWeakDictionary.h"

NSString * const ECAttributedFileBufferWillChangeAttributesNotificationName = @"ECAttributedFileBufferWillSetAttributesNotificationName";
NSString * const ECAttributedFileBufferDidChangeAttributesNotificationName = @"ECAttributedFileBufferDidSetAttributesNotificationName";
NSString * const ECAttributedFileBufferAttributedStringKey = @"ECAttributedFileBufferAttributedStringKey";
NSString * const ECAttributedFileBufferAttributeNameKey = @"ECAttributedFileBufferAttributeNameKey";
NSString * const ECAttributedFileBufferAttributesChangeKey = @"ECAttributedFileBufferAttributesChangeKey";
NSString * const ECAttributedFileBufferAttributesKey = @"ECAttributedFileBufferAttributesKey";

static ECWeakDictionary *_attributedFileBuffers;

@interface ECAttributedFileBuffer ()
{
    NSURL *_fileURL;
    NSMutableAttributedString *_contents;
}
@end

@implementation ECAttributedFileBuffer

+ (void)initialize
{
    _attributedFileBuffers = [[ECWeakDictionary alloc] init];
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    self = [_attributedFileBuffers objectForKey:fileURL];
    if (self)
        return self;
    self = [super init];
    if (!self)
        return nil;
    _fileURL = fileURL;
    _contents = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]];
    if (!_contents)
        _contents = [[NSMutableAttributedString alloc] initWithString:@""];
    [_attributedFileBuffers setObject:self forKey:fileURL];
    return self;
}

- (NSURL *)fileURL
{
    return _fileURL;
}

- (void)save;
{
    [self saveToFileURL:_fileURL error:NULL];
}

- (BOOL)saveToFileURL:(NSURL *)fileURL error:(NSError *__autoreleasing *)error
{
    return [[_contents string] writeToURL:_fileURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (NSUInteger)length
{
    return [_contents length];
}

- (NSString *)stringInRange:(NSRange)range
{
    return [[_contents string] substringWithRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[[_contents string] substringWithRange:range]])
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, string, ECFileBufferStringKey, [[NSAttributedString alloc] initWithString:string], ECAttributedFileBufferAttributedStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    [_contents replaceCharactersInRange:range withString:string];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidReplaceCharactersNotificationName object:self userInfo:change];
}

- (NSAttributedString *)attributedStringInRange:(NSRange)range
{
    return [_contents attributedSubstringFromRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attributedString
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![attributedString length])
        return;
    // replacing a substring with an equal string, no change required
    if ([attributedString isEqualToAttributedString:[_contents attributedSubstringFromRange:range]])
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, [attributedString string], ECFileBufferStringKey, attributedString, ECAttributedFileBufferAttributedStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidReplaceCharactersNotificationName object:self userInfo:change];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECAttributedFileBufferAttributesChangeSet], ECAttributedFileBufferAttributesChangeKey, attributes, ECAttributedFileBufferAttributesKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents setAttributes:attributes range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECAttributedFileBufferAttributesChangeAdd], ECAttributedFileBufferAttributesChangeKey, attributes, ECAttributedFileBufferAttributesKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents addAttributes:attributes range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

- (void)removeAttribute:(NSString *)attributeName range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    ECASSERT([attributeName length]);
    if (!range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECAttributedFileBufferAttributesChangeRemove], ECAttributedFileBufferAttributesChangeKey, attributeName, ECAttributedFileBufferAttributeNameKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents removeAttribute:attributeName range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECAttributedFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

@end
