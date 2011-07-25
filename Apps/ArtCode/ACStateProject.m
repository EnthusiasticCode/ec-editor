//
//  ACStateProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateInternal.h"
#import "ACProject.h"
#import "ACURL.h"
#import "ACStateProject.h"
#import "ACStateNodeInternal.h"
#import "ACStateOrderedSetWrapper.h"

@interface ACStateProject ()
{
    ACProject *_document;
}
@end

@implementation ACStateProject

@synthesize URL = _URL;

- (void)setURL:(NSURL *)URL
{
    ECASSERT(URL);
    [self willChangeValueForKey:@"URL"];
    [self willChangeValueForKey:@"name"];
    _URL = URL;
    [self didChangeValueForKey:@"name"];
    [self didChangeValueForKey:@"URL"];
}

- (NSString *)name
{
    return [self.URL ACProjectName];
}

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    self.URL = [NSURL ACURLForProjectWithName:name];
}

- (NSUInteger)index
{
    return [[ACState sharedState] indexOfProjectWithURL:self.URL];
}

- (void)setIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"index"];
    [[ACState sharedState] setIndex:index forProjectWithURL:self.URL];
    [self didChangeValueForKey:@"index"];
}

- (NSOrderedSet *)children
{
    ECASSERT(_document);
    return [ACStateOrderedSetWrapper orderedSetWithOrderedSet:_document.children];
}

- (id)initWithURL:(NSURL *)URL
{
    self = [super initWithURL:URL];
    if (!self)
        return nil;
    _URL = URL;
    _document = [[ACProject alloc] initWithFileURL:[self documentDirectory]];
    return self;
}

- (id)initWithObject:(id)object
{
    ECASSERT([object isKindOfClass:[ACProject class]]);
    self = [super initWithObject:object];
    if (!self)
        return nil;
    _URL = [object fileURL];
    _document = object;
    return self;
}

- (void)delete
{
    [super delete];
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(_document);
    [_document openWithCompletionHandler:completionHandler];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(_document);
    [_document closeWithCompletionHandler:completionHandler];
}

- (NSURL *)documentDirectory
{
    return [[[ACState sharedState] stateProjectsDirectory] URLByAppendingPathComponent:[self.URL ACProjectName]];
}

- (NSURL *)contentDirectory
{
    return [[[[ACState sharedState] stateProjectsDirectory] URLByAppendingPathComponent:[self.URL ACProjectName]] URLByAppendingPathComponent:ACProjectContentDirectory];
}

@end
