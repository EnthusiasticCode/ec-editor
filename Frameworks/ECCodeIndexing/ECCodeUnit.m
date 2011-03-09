//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
#import "ECCodeIndex(Private).h"
#import "ECCodeUnit(Private).h"

@interface ECCodeUnit ()
{
    @private
    id<ECCodeUnitPlugin> plugin_;
    NSMutableDictionary *filePointers_;
}
@property (nonatomic) BOOL filesHaveUnsavedContent;
@end

@implementation ECCodeUnit

@synthesize index = index_;
@synthesize url = url_;
@synthesize language = language_;
@synthesize filesHaveUnsavedContent = filesHaveUnsavedContent_;

- (void)dealloc
{
    for (NSObject<ECCodeIndexingFileObserving> * file in [filePointers_ allValues])
    {
        [self removeObserversFromFile:file];
    }
    [self.index removeTranslationUnitForURL:self.url];
    [index_ release];
    [url_ release];
    [language_ release];
    [plugin_ release];
    [filePointers_ release];
    [super dealloc];
}

- (id)initWithIndex:(ECCodeIndex *)index url:(NSURL *)url language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin
{
    self = [super init];
    if (!self)
        return nil;
    if (!plugin || !language || !url || !index)
    {
        [self release];
        return nil;
    }
    index_ = [index retain];
    url_ = [url copy];
    language_ = [language copy];
    plugin_ = [plugin retain];
    filePointers_ = [[NSMutableDictionary dictionary] retain];
    return self;
}

+ (id)unitWithIndex:(ECCodeIndex *)index url:(NSURL *)url language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin
{
    id codeUnit = [self alloc];
    codeUnit = [codeUnit initWithIndex:index url:url language:language plugin:plugin];
    return [codeUnit autorelease];
}

- (BOOL)isDependentOnFile:(NSURL *)fileURL
{
    return [plugin_ isDependentOnFile:fileURL];
}

- (void)setNeedsReparse
{
    self.filesHaveUnsavedContent = YES;
}

- (NSArray *)completionsWithSelection:(NSRange)selection
{
    if (![plugin_ respondsToSelector:@selector(completionsWithSelection:)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ completionsWithSelection:selection];
}

- (NSArray *)diagnostics
{
    if (![plugin_ respondsToSelector:@selector(diagnostics)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ diagnostics];
}

- (NSArray *)fixIts
{
    if (![plugin_ respondsToSelector:@selector(fixIts)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ fixIts];
}

- (NSArray *)tokensInRange:(NSRange)range
{
    if (![plugin_ respondsToSelector:@selector(tokensInRange:)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ tokensInRange:range];
}

- (NSArray *)tokens;
{
    if (![plugin_ respondsToSelector:@selector(tokens)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ tokens];
}

- (NSArray *)observedFiles
{
    NSMutableArray *observedFiles = [NSMutableArray arrayWithCapacity:[filePointers_ count]];
    for (NSValue *pointerWrapper in [filePointers_ allValues])
        [observedFiles addObject:[pointerWrapper nonretainedObjectValue]];
    return observedFiles;
}

- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    NSURL *fileURL = file.URL;
    if (![self isDependentOnFile:fileURL])
        return NO;
    [filePointers_ setObject:[NSValue valueWithNonretainedObject:file] forKey:file.URL];
    [file addObserver:self forKeyPath:@"unsavedContent" options:0 context:NULL];
    return YES;
}

- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    [filePointers_ removeObjectForKey:file.URL];
    [file removeObserver:self forKeyPath:@"unsavedContent"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.filesHaveUnsavedContent = YES;
}

@end
