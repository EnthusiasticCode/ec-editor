//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECClangCodeIndexer.h"

#import <objc/runtime.h>

static NSMutableDictionary *_codeIndexerClassesByLanguage;
static NSMutableDictionary *_codeIndexerClassesByExtension;
static NSMutableSet *_handledLanguages;
static NSMutableSet *_handledExtensions;

@implementation ECCodeIndexer

@synthesize language = _language;
@synthesize source = _source;

- (id)initWithSource:(NSString *)source language:(NSString *)language
{
    if (self.source)
        return self;
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if (![fileManager fileExistsAtPath:source])
        return nil;
    self = [[[_codeIndexerClassesByLanguage objectForKey:language] alloc] initWithSource:source language:language];
    return self;
}

- (id)initWithSource:(NSString *)source
{
    if (self.source)
        return self;
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if (![fileManager fileExistsAtPath:source])
        return nil;
    NSString *extension = [source pathExtension];
    self = [[[_codeIndexerClassesByExtension objectForKey:extension] alloc] initWithSource:source];
    return self;
}

+ (void)loadLanguages
{
    if (_codeIndexerClassesByLanguage && _codeIndexerClassesByExtension && _handledLanguages && _handledExtensions)
        return;
    int numClasses;
    numClasses = objc_getClassList(NULL, 0);
    if (!numClasses)
        return;
    Class *classes = NULL;
    NSMutableArray *subclasses;
    [_handledLanguages release];
    _handledLanguages = [[NSMutableSet alloc] init];
    [_codeIndexerClassesByLanguage release];
    _codeIndexerClassesByLanguage = [[NSMutableDictionary alloc] init];
    [_handledExtensions release];
    _handledExtensions = [[NSMutableSet alloc] init];
    [_codeIndexerClassesByExtension release];
    _codeIndexerClassesByExtension = [[NSMutableDictionary alloc] init];
    subclasses = [[NSMutableArray alloc] initWithCapacity:numClasses];
    classes = malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; i++)
    {
        if (class_getSuperclass(classes[i]) == [ECCodeIndexer class])
            [subclasses addObject:classes[i]];
    }
    for (Class subclass in subclasses)
    {
        for (NSString *language in [subclass handledLanguages])
        {
            [_codeIndexerClassesByLanguage setObject:subclass forKey:language];
            [_handledLanguages addObject:language];
        }
        for (NSString *extension in [subclass handledExtensions])
        {
            [_codeIndexerClassesByExtension setObject:subclass forKey:extension];
            [_handledExtensions addObject:extension];
        }
     }
    free(classes);
    [subclasses release];
}

+ (void)unloadLanguages
{
    [_codeIndexerClassesByLanguage release];
    [_codeIndexerClassesByExtension release];
    [_handledLanguages release];
    [_handledExtensions release];
}

+ (NSArray *)handledLanguages
{
    return [_handledLanguages allObjects];
}

+ (NSArray *)handledExtensions
{
    return [_handledExtensions allObjects];
}

- (NSArray *)completionsForSelection:(NSRange)selection withUnsavedFileBuffers:(NSDictionary *)fileBuffers
{
    return nil;
}

- (NSArray *)completionsForSelection:(NSRange)selection
{
    return [self completionsForSelection:selection withUnsavedFileBuffers:nil];
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)tokensForRange:(NSRange)range withUnsavedFileBuffers:(NSDictionary *)fileBuffers
{
    return nil;
}

- (NSArray *)tokensForRange:(NSRange)range
{
    return [self tokensForRange:range withUnsavedFileBuffers:nil];
}

- (NSArray *)tokensWithUnsavedFileBuffers:(NSDictionary *)fileBuffers
{
    if (!self.source || ![self.source length])
        return nil;
    NSString *sourceBuffer = [fileBuffers objectForKey:self.source];
    if (sourceBuffer)
        return [self tokensForRange:NSMakeRange(0, [sourceBuffer length]) withUnsavedFileBuffers:fileBuffers];
    NSError *error = nil;
    NSFileWrapper *sourceWrapper = [[[NSFileWrapper alloc] initWithURL:[NSURL fileURLWithPath:self.source] options:0 error:&error] autorelease];
    if (error)
    {
        NSLog(@"error: %@", error);
        return nil;
    }
    return [self tokensForRange:NSMakeRange(0, [[sourceWrapper regularFileContents] length]) withUnsavedFileBuffers:fileBuffers];
}

- (NSArray *)tokens
{
    return [self tokensWithUnsavedFileBuffers:nil];
}

@end
