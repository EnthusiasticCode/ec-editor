//
//  ECClangCodeCompletionChunk.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCompletionChunk.h"

@interface ECClangCodeCompletionChunk ()
{
    enum CXCompletionChunkKind _kind;
    NSString *_text;
    id<ECCodeCompletionString>_completionString;
}
@end

@implementation ECClangCodeCompletionChunk

- (id)initWithKind:(enum CXCompletionChunkKind)kind text:(NSString *)text completionString:(id<ECCodeCompletionString>)completionString
{
    self = [super init];
    if (!self)
        return nil;
    _kind = kind;
    _text = text;
    _completionString = completionString;
    return self;
}

- (enum CXCompletionChunkKind)kind
{
    return _kind;
}

- (NSString *)text
{
    return _text;
}

- (id<ECCodeCompletionString>)completionString
{
    return _completionString;
}

@end
