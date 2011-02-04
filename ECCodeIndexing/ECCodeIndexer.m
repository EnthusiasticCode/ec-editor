//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECClangCodeIndexer.h"

@implementation ECCodeIndexer

@synthesize source = _source;

- (void)dealloc
{
    self.source = nil;
    [super dealloc];
}

- (id)init
{
    [self release];
    self = [[ECClangCodeIndexer alloc] init];
    return self;
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
