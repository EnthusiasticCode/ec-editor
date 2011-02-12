//
//  ECCodeIndexerSpec.m
//  edit
//
//  Created by Uri Baghin on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ECCodeIndexing/ECCodeIndexer.h>
#import "Kiwi/Kiwi.h"

SPEC_BEGIN(ECCodeIndexingSpec)

describe(@"A code indexer",^
{
    __block ECCodeIndexer *codeIndexer;
    __block NSURL *cFileURL;
    beforeAll(^
    {
        NSString *cFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"];
        cFileURL = [[NSURL alloc] initFileURLWithPath:cFilePath];
        [[NSData dataWithBytes:"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" length:79] writeToURL:cFileURL atomically:NO];
        [ECCodeIndexer loadLanguages];
    });
    
    afterAll(^
    {
        [cFileURL release];
        [ECCodeIndexer unloadLanguages];
    });
    
    beforeEach(^
    {
        codeIndexer = [ECCodeIndexer alloc];
    });
    
    afterEach(^
    {
        [codeIndexer release];
    });
    
    it(@"loads language specific code indexer classes", ^
    {
        [[[ECCodeIndexer should] have:4] handledLanguages];
    });
    
    it(@"doesn't have a language set by default", ^
    {
        codeIndexer = [codeIndexer init];
        [[codeIndexer language] shouldBeNil];
    });
    
    it(@"doesn't have a source set by default", ^
    {
        codeIndexer = [codeIndexer init];
        [[codeIndexer source] shouldBeNil];
    });
    
    it(@"doesn't accept an invalid source", ^
    {
        codeIndexer = [codeIndexer initWithSource:nil];
        [[codeIndexer source] shouldBeNil];
    });
    
    it(@"accepts a valid source", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFileURL];
        [[[codeIndexer source] should] equal:cFileURL];
    });
    
    it(@"sets language based on source", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFileURL];
        [[[codeIndexer language] should] equal:@"C"];
    });
    
    it(@"can override the automatically set language", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFileURL language:@"Objective C"];
        [[[codeIndexer language] should] equal:@"Objective C"];
    });
    
    describe(@"with an example C source", ^
    {
        beforeEach(^
        {
            codeIndexer = [codeIndexer initWithSource:cFileURL];
        });
        
        it(@"loads without diagnostics", ^
        {
            [[[codeIndexer diagnostics] should] beEmpty];
        });
        
        it(@"has exactly 25 tokens", ^
        {
            [[[codeIndexer should] have:25] tokens];
        });
        
        it(@"have at least 400 completions", ^
        {
            [[[codeIndexer completionsForSelection:NSMakeRange(57, 0)] should] haveCountOfAtLeast:400];
        });
    });
});

SPEC_END
