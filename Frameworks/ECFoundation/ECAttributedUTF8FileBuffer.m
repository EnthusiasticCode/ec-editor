//
//  ECFileBuffer.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECAttributedUTF8FileBuffer.h"
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

@interface ECAttributedUTF8FileBuffer ()
{
    NSURL *_fileURL;
    NSMutableAttributedString *_contents;
}
@end

@implementation ECAttributedUTF8FileBuffer

+ (void)initialize
{
    _fileBuffers = [[ECWeakDictionary alloc] init];
}

- (id)initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    ECAttributedUTF8FileBuffer *existingFileBuffer = [_fileBuffers objectForKey:fileURL];
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
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, [string length] ? string : [NSNull null], ECFileBufferStringKey, [string length] ? [[NSAttributedString alloc] initWithString:string] : [NSNull null], ECFileBufferAttributedStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    if ([string length])
        [_contents replaceCharactersInRange:range withString:string];
    else
        [_contents deleteCharactersInRange:range];
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
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, [attributedString length] ? [attributedString string] : [NSNull null], ECFileBufferStringKey, [attributedString length] ? attributedString : [NSNull null], ECFileBufferAttributedStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    if ([attributedString length])
        [_contents replaceCharactersInRange:range withAttributedString:attributedString];
    else
        [_contents deleteCharactersInRange:range];
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

- (NSUInteger)numberOfMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT(regexp);
    return [regexp numberOfMatchesInString:[_contents string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range
{
    ECASSERT(regexp);
    return [regexp matchesInString:[_contents string] options:options range:range];
}

- (NSArray *)matchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options
{
    return [self matchesOfRegexp:regexp options:options range:NSMakeRange(0, [self length])];
}

- (void)replaceMatchesOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)replacementTemplate
{
    ECASSERT(regexp && replacementTemplate);
    [self replaceCharactersInRange:NSMakeRange(0, [self length]) withString:[regexp stringByReplacingMatchesInString:[_contents string] options:options range:range withTemplate:replacementTemplate]];
}

- (NSRange)replaceMatch:(NSTextCheckingResult *)match withTemplate:(NSString *)replacementTemplate offset:(NSInteger)offset
{
    ECASSERT(match && replacementTemplate);
    
    NSRange replacementRange = match.range;
    NSString *replacementString = [match.regularExpression replacementStringForResult:match inString:[_contents string] offset:offset template:replacementTemplate];
    
    replacementRange.location += offset;
    [self replaceCharactersInRange:replacementRange withString:replacementString];
    replacementRange.length = replacementString.length;
    
    return replacementRange;
}

@end
