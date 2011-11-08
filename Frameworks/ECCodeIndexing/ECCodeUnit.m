//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"
#import "ECCodeIndex+Subclass.h"

@interface ECCodeUnit ()
{
    ECCodeIndex *_index;
    NSURL *_fileURL;
    NSString *_scope;
}
@end

@implementation ECCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index file:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(index && fileURL);
    self = [super init];
    if (!self)
        return nil;
    _index = index;
    _fileURL = fileURL;
    _scope = scope;
    return self;
}

- (ECCodeIndex *)index
{
    return _index;
}

- (NSURL *)fileURL
{
    return _fileURL;
}

- (NSString *)scope
{
    return _scope;
}

- (NSArray *)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)tokens
{
    return [self tokensInRange:NSMakeRange(0, [[[self index] contentsForFile:self.fileURL] length])];
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return nil;
}

- (NSArray *)annotatedTokens
{
    return [self annotatedTokensInRange:NSMakeRange(0, [[[self index] contentsForFile:self.fileURL] length])];
}

- (NSArray *)annotatedTokensInRange:(NSRange)range
{
    return nil;
}

@end