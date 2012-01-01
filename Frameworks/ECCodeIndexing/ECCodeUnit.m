//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit+Subclass.h"
#import "ECCodeIndex+Subclass.h"
#import <ECFoundation/ECFileBuffer.h>

@interface ECCodeUnit ()
{
    NSOperationQueue *_consumerOperationQueue;
    ECCodeIndex *_index;
    ECFileBuffer *_fileBuffer;
    NSString *_scope;
}
@end

@implementation ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer scope:(NSString *)scope
{
    ECASSERT(index && fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _consumerOperationQueue = [NSOperationQueue currentQueue];
    _index = index;
    _fileBuffer = fileBuffer;
    [_fileBuffer addConsumer:self];
    _scope = scope;
    return self;
}

- (void)dealloc
{
    [_fileBuffer removeConsumer:self];
}

- (ECCodeIndex *)index
{
    return _index;
}

- (ECFileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (NSString *)scope
{
    return _scope;
}

- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)tokens
{
    return [self tokensInRange:NSMakeRange(0, [[self fileBuffer] length])];
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return nil;
}

- (NSArray *)annotatedTokens
{
    return [self annotatedTokensInRange:NSMakeRange(0, [[self fileBuffer] length])];
}

- (NSArray *)annotatedTokensInRange:(NSRange)range
{
    return nil;
}

#pragma mark - ECFileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

@end
