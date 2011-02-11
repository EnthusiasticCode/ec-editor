//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECClangCodeIndexer.h"
#import <ECAdditions/NSURL+ECAdditions.h>

#import <objc/runtime.h>
#import <MobileCoreServices/MobileCoreServices.h>

static NSMutableDictionary *_codeIndexerClassesByLanguage;
static NSMutableDictionary *_codeIndexerClassesByUTI;
static NSMutableSet *_handledLanguages;
static NSMutableSet *_handledUTIs;

@implementation ECCodeIndexer

@synthesize language = _language;
@synthesize source = _source;

- (id)initWithSource:(NSURL *)source language:(NSString *)language
{
    if (self.source)
        return self;
    if (![source isFileURLAndExists])
        return nil;
    self = [[[_codeIndexerClassesByLanguage objectForKey:language] alloc] initWithSource:source language:language];
    return self;
}

- (id)initWithSource:(NSURL *)source
{
    if (self.source)
        return self;
    if (![source isFileURLAndExists])
        return nil;
    NSString *extension = [source pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
    self = [[[_codeIndexerClassesByUTI objectForKey:(NSString *)UTI] alloc] initWithSource:source];
    CFRelease(UTI);
    return self;
}

+ (void)loadLanguages
{
    if (_codeIndexerClassesByLanguage && _codeIndexerClassesByUTI && _handledLanguages && _handledUTIs)
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
    [_handledUTIs release];
    _handledUTIs = [[NSMutableSet alloc] init];
    [_codeIndexerClassesByUTI release];
    _codeIndexerClassesByUTI = [[NSMutableDictionary alloc] init];
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
        for (NSString *UTI in [subclass handledUTIs])
        {
            [_codeIndexerClassesByUTI setObject:subclass forKey:UTI];
            [_handledUTIs addObject:UTI];
        }
     }
    free(classes);
    [subclasses release];
}

+ (void)unloadLanguages
{
    [_codeIndexerClassesByLanguage release];
    [_codeIndexerClassesByUTI release];
    [_handledLanguages release];
    [_handledUTIs release];
}

+ (NSArray *)handledLanguages
{
    return [_handledLanguages allObjects];
}

+ (NSArray *)handledUTIs
{
    return [_handledUTIs allObjects];
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
    if (!self.source)
        return nil;
    NSString *sourceBuffer = [fileBuffers objectForKey:self.source];
    if (sourceBuffer)
        return [self tokensForRange:NSMakeRange(0, [sourceBuffer length]) withUnsavedFileBuffers:fileBuffers];
    NSError *error = nil;
    NSFileWrapper *sourceWrapper = [[[NSFileWrapper alloc] initWithURL:self.source options:0 error:&error] autorelease];
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
