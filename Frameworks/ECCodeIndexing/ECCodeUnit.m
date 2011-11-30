//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit+Subclass.h"
#import "ECCodeIndex+Subclass.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>

@interface ECCodeUnit ()
{
    ECCodeIndex *_index;
    ECAttributedUTF8FileBuffer *_fileBuffer;
    NSString *_scope;
}
@end

@implementation ECCodeUnit

- (ECCodeIndex *)index
{
    return _index;
}

- (ECAttributedUTF8FileBuffer *)fileBuffer
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

@end

@implementation ECCodeUnit (Internal)

- (id)initWithIndex:(ECCodeIndex *)index fileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope
{
    ECASSERT(index && fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _index = index;
    _fileBuffer = fileBuffer;
    _scope = scope;
    return self;
}

@end
