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
@property (nonatomic, retain) NSMutableDictionary *filePointers;
@end

@implementation ECCodeUnit

@synthesize index = index_;
@synthesize url = url_;
@synthesize language = language_;
@synthesize needsReparse = needsReparse_;
@synthesize filePointers = filePointers_;

- (id)init
{
    self = [super init];
    if (self)
        self.filePointers = [NSMutableDictionary dictionary];
    return self;
}

- (void)dealloc
{
    for (NSObject<ECCodeIndexingFileObserving> * file in [self.filePointers allValues])
    {
        [self removeObserversFromFile:file];
    }
    [self.index removeTranslationUnitForURL:self.url];
    [index_ release];
    [url_ release];
    [language_ release];
    self.filePointers = nil;
    [super dealloc];
}

- (BOOL)isDependentOnFile:(NSURL *)fileURL
{
    return NO;
}

- (NSArray *)completionsWithSelection:(NSRange)selection
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)fixIts
{
    return nil;
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return nil;
}

- (NSArray *)tokens;
{
    return nil;
}

- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    NSURL *fileURL = file.URL;
    if (![self isDependentOnFile:fileURL])
        return NO;
    [self.filePointers setObject:[NSValue valueWithNonretainedObject:file] forKey:file.URL];
    [file addObserver:self forKeyPath:@"unsavedContent" options:0 context:NULL];
    return YES;
}

- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    [self.filePointers removeObjectForKey:file.URL];
    [file removeObserver:self forKeyPath:@"unsavedContent"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.needsReparse = YES;
}

@end
