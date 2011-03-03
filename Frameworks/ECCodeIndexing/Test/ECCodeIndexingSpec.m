//
//  ECCodeIndexerSpec.m
//  edit
//
//  Created by Uri Baghin on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "../../Kiwi/Kiwi.h"

SPEC_BEGIN(ECCodeIndexingSpec)

describe(@"A code indexer",^
{
    __block ECCodeIndex *codeIndex;
    __block NSURL *cFileURL;
    beforeAll(^
    {
        NSString *cFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"];
        cFileURL = [[NSURL alloc] initFileURLWithPath:cFilePath];
        [[NSData dataWithBytes:"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" length:79] writeToURL:cFileURL atomically:NO];
    });
    
    afterAll(^
    {
        [cFileURL release];
    });
    
    beforeEach(^
    {
        codeIndex = [ECCodeIndex alloc];
    });
    
    afterEach(^
    {
        [codeIndex release];
    });
    
    it(@"loads language specific code indexer classes", ^
    {
        [[[ECCodeIndex should] have:4] languageToExtensionMap];
    });
    
    it(@"doesn't have a language set by default", ^
    {
        codeIndex = [codeIndex init];
        [[codeIndex language] shouldBeNil];
    });
    
    it(@"doesn't have a source set by default", ^
    {
        codeIndex = [codeIndex init];
        [[codeIndex source] shouldBeNil];
    });
    
    it(@"doesn't accept an invalid source", ^
    {
        codeIndex = [codeIndex initWithSource:nil];
        [[codeIndex source] shouldBeNil];
    });
    
    it(@"accepts a valid source", ^
    {
        codeIndex = [codeIndex initWithSource:cFileURL];
        [[[codeIndex source] should] equal:cFileURL];
    });
    
    it(@"sets language based on source", ^
    {
        codeIndex = [codeIndex initWithSource:cFileURL];
        [[[codeIndex language] should] equal:@"C"];
    });
    
    it(@"can override the automatically set language", ^
    {
        codeIndex = [codeIndex initWithSource:cFileURL language:@"Objective C"];
        [[[codeIndex language] should] equal:@"Objective C"];
    });
    
    describe(@"with an example C source", ^
    {
        beforeEach(^
        {
            codeIndex = [codeIndex initWithSource:cFileURL];
        });
        
        it(@"loads without diagnostics", ^
        {
            [[[codeIndex diagnostics] should] beEmpty];
        });
        
        it(@"has exactly 25 tokens", ^
        {
            [[[codeIndex should] have:25] tokens];
        });
        
        it(@"have at least 400 completions", ^
        {
            [[[codeIndex completionsForSelection:NSMakeRange(57, 0)] should] haveCountOfAtLeast:400];
        });
    });
});

SPEC_END
