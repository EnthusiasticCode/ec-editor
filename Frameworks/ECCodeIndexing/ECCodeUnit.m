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
@synthesize file = file_;
@synthesize language = language_;
@synthesize filesHaveUnsavedContent = filesHaveUnsavedContent_;

- (void)dealloc
{
    for (NSObject<ECCodeIndexingFileObserving> *fileObject in [filePointers_ allValues])
    {
        [self removeObserversFromFile:fileObject];
    }
    [self.index removeTranslationUnitForFile:self.file];
    [index_ release];
    [file_ release];
    [language_ release];
    [plugin_ release];
    [filePointers_ release];
    [super dealloc];
}

- (id)initWithIndex:(ECCodeIndex *)index file:(NSString *)file language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin
{
    self = [super init];
    if (!self)
        return nil;
    if (!plugin || !language || !file || !index)
    {
        [self release];
        return nil;
    }
    index_ = [index retain];
    file_ = [file copy];
    language_ = [language copy];
    plugin_ = [plugin retain];
    filePointers_ = [[NSMutableDictionary dictionary] retain];
    return self;
}

+ (id)unitWithIndex:(ECCodeIndex *)index file:(NSString *)file language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin
{
    id codeUnit = [self alloc];
    codeUnit = [codeUnit initWithIndex:index file:file language:language plugin:plugin];
    return [codeUnit autorelease];
}

- (BOOL)isDependentOnFile:(NSString *)file
{
    return [plugin_ isDependentOnFile:file];
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

- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors
{
    if (![plugin_ respondsToSelector:@selector(tokensInRange:withCursors:)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ tokensInRange:range withCursors:attachCursors];
}

- (NSArray *)tokensWithCursors:(BOOL)attachCursors
{
    if (![plugin_ respondsToSelector:@selector(tokensWithCursors:)])
        return nil;
    if (self.filesHaveUnsavedContent)
        [plugin_ reparseDependentFiles:[self observedFiles]];
    return [plugin_ tokensWithCursors:attachCursors];
}

- (ECCodeCursor *)cursor
{
    return nil;
}

- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)observedFiles
{
    NSMutableArray *observedFiles = [NSMutableArray arrayWithCapacity:[filePointers_ count]];
    for (NSValue *pointerWrapper in [filePointers_ allValues])
        [observedFiles addObject:[pointerWrapper nonretainedObjectValue]];
    return observedFiles;
}

- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    NSString *file = fileObject.file;
    if (![self isDependentOnFile:file])
        return NO;
    [filePointers_ setObject:[NSValue valueWithNonretainedObject:fileObject] forKey:file];
    [file addObserver:self forKeyPath:@"unsavedContent" options:0 context:NULL];
    return YES;
}

- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    [filePointers_ removeObjectForKey:fileObject.file];
    [fileObject removeObserver:self forKeyPath:@"unsavedContent"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.filesHaveUnsavedContent = YES;
}

@end
