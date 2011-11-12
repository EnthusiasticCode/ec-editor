//
//  ECFileBuffer.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFileBuffer.h"
#import "ECWeakDictionary.h"

NSString * const ECFileBufferWillReplaceCharactersNotificationName = @"ECFileBufferReplacementNotificationName";
NSString * const ECFileBufferDidReplaceCharactersNotificationName = @"ECFileBufferDidReplaceCharactersNotificationName";
NSString * const ECFileBufferWillChangeAttributesNotificationName = @"ECFileBufferWillSetAttributesNotificationName";
NSString * const ECFileBufferDidChangeAttributesNotificationName = @"ECFileBufferDidSetAttributesNotificationName";
NSString * const ECFileBufferRangeKey = @"ECFileBufferRangeKey";
NSString * const ECFileBufferStringKey = @"ECFileBufferStringKey";
NSString * const ECFileBufferAttributedStringKey = @"ECFileBufferAttributedStringKey";
NSString * const ECFileBufferAttributeNameKey = @"ECFileBufferAttributeNameKey";
NSString * const ECFileBufferAttributesChangeKey = @"ECFileBufferAttributesChangeKey";
NSString * const ECFileBufferAttributesKey = @"ECFileBufferAttributesKey";

static ECWeakDictionary *_fileBuffers;

@interface ECFileBuffer ()
{
    NSURL *_fileURL;
    NSMutableAttributedString *_contents;
}
@end

@implementation ECFileBuffer

+ (void)initialize
{
    _fileBuffers = [[ECWeakDictionary alloc] init];
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    ECFileBuffer *existingFileBuffer = [_fileBuffers objectForKey:fileURL];
    if (existingFileBuffer)
        return existingFileBuffer;
    self = [super init];
    if (!self)
        return nil;
    _fileURL = fileURL;
    _contents = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]];
    if (!_contents)
        _contents = [[NSMutableAttributedString alloc] initWithString:@""];
    [_fileBuffers setObject:self forKey:fileURL];
    return self;
}

- (NSURL *)fileURL
{
    return _fileURL;
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
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, string, ECFileBufferStringKey, [[NSAttributedString alloc] initWithString:string], ECFileBufferAttributedStringKey, nil];
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
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, [attributedString string], ECFileBufferStringKey, attributedString, ECFileBufferAttributedStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidReplaceCharactersNotificationName object:self userInfo:change];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECFileBufferAttributesChangeSet], ECFileBufferAttributesChangeKey, attributes, ECFileBufferAttributesKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents setAttributes:attributes range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    if (![attributes count] || !range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECFileBufferAttributesChangeAdd], ECFileBufferAttributesChangeKey, attributes, ECFileBufferAttributesKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents addAttributes:attributes range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

- (void)removeAttribute:(NSString *)attributeName range:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    ECASSERT([attributeName length]);
    if (!range.length)
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:ECFileBufferAttributesChangeRemove], ECFileBufferAttributesChangeKey, attributeName, ECFileBufferAttributeNameKey, [NSValue valueWithRange:range], ECFileBufferRangeKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillChangeAttributesNotificationName object:self userInfo:change];
    [_contents removeAttribute:attributeName range:range];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidChangeAttributesNotificationName object:self userInfo:change];
}

@end
