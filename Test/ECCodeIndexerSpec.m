//
//  ECCodeIndexerSpec.m
//  edit
//
//  Created by Uri Baghin on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "Kiwi.h"

SPEC_BEGIN(ECCodeIndexerSpec)

describe(@"A code indexer",^
{
    __block ECCodeIndexer *codeIndexer;
    __block NSString *cFilePath;
    beforeAll(^
    {
        cFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"] retain];
        [[NSData dataWithBytes:"#include <stdio.h>\n int main(int argc, char **argv) { printf(\"hello world\n\"); }" length:80] writeToFile:cFilePath atomically:YES];
    });
    
    afterAll(^
    {
        [cFilePath release];
    });
    
    beforeEach(^
    {
        codeIndexer = [[ECCodeIndexer alloc] init];
    });
    afterEach(^
    {
        [codeIndexer release];
    });
    
    it(@"initializes", ^
    {
        [codeIndexer shouldNotBeNil];
    });
    
    it(@"has a source property", ^
    {
        [[codeIndexer should] respondToSelector:@selector(source)];
        [[codeIndexer should] respondToSelector:@selector(setSource:)];
    });
    
    it(@"doesn't have a source by default", ^
    {
        [[codeIndexer source] shouldBeNil];
    });
    
    it(@"doesn't accept an invalid source", ^
    {
        [codeIndexer setSource:@"thisfiledoesnotexist"];
        [[codeIndexer source] shouldBeNil];
    });
    
    it(@"accepts a new source", ^
    {
        [codeIndexer setSource:cFilePath];
        [[[codeIndexer source] should] equal:cFilePath];
    });
    
    
});

SPEC_END
