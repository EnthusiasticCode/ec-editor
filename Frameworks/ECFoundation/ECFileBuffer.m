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
NSString * const ECFileBufferRangeKey = @"ECFileBufferRangeKey";
NSString * const ECFileBufferStringKey = @"ECFileBufferStringKey";

static ECWeakDictionary *_fileBuffers;

@interface ECFileBuffer ()
{
    NSURL *_fileURL;
    NSMutableString *_contents;
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
    self = [_fileBuffers objectForKey:fileURL];
    if (self)
        return self;
    self = [super init];
    if (!self)
        return nil;
    _fileURL = fileURL;
    _contents = [NSMutableString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
    if (!_contents)
        _contents = [NSMutableString string];
    [_fileBuffers setObject:self forKey:fileURL];
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
    return [_contents writeToURL:_fileURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (NSUInteger)length
{
    return [_contents length];
}

- (NSString *)stringInRange:(NSRange)range
{
    return [_contents substringWithRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
    ECASSERT(NSMaxRange(range) <= [_contents length]);
    // replacing an empty range with an empty string, no change required
    if (!range.length && ![string length])
        return;
    // replacing a substring with an equal string, no change required
    if ([string isEqualToString:[_contents substringWithRange:range]])
        return;
    NSDictionary *change = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRange:range], ECFileBufferRangeKey, string, ECFileBufferStringKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferWillReplaceCharactersNotificationName object:self userInfo:change];
    [_contents replaceCharactersInRange:range withString:string];
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileBufferDidReplaceCharactersNotificationName object:self userInfo:change];
}

@end
