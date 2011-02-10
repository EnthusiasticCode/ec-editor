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
        [[NSData dataWithBytes:"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" length:79] writeToFile:cFilePath atomically:YES];
        [ECCodeIndexer loadLanguages];
    });
    
    afterAll(^
    {
        [ECCodeIndexer unloadLanguages];
        [cFilePath release];
    });
    
    beforeEach(^
    {
        codeIndexer = [ECCodeIndexer alloc];
    });
    
    afterEach(^
    {
        [codeIndexer release];
    });
    
    it(@"initializes", ^
    {
        codeIndexer = [codeIndexer init];
        [codeIndexer shouldNotBeNil];
    });
    
    it(@"loads language specific code indexer classes", ^
    {
        [[[ECCodeIndexer should] have:4] handledLanguages];
    });

    it(@"has a readonly language property", ^
    {
        [[codeIndexer should] respondToSelector:@selector(language)];
        [[codeIndexer shouldNot] respondToSelector:@selector(setLanguage:)];
    });
    
    it(@"has a readonly source property", ^
    {
        [[codeIndexer should] respondToSelector:@selector(source)];
        [[codeIndexer shouldNot] respondToSelector:@selector(setSource:)];
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
        codeIndexer = [codeIndexer initWithSource:@"thisfiledoesnotexist"];
        [[codeIndexer source] shouldBeNil];
    });
    
    it(@"accepts a valid source", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFilePath];
        [[[codeIndexer source] should] equal:cFilePath];
    });
    
    it(@"sets language based on source", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFilePath];
        [[[codeIndexer language] should] equal:@"C"];
    });
    
    it(@"can override the automatically set language", ^
    {
        codeIndexer = [codeIndexer initWithSource:cFilePath language:@"Objective C"];
        [[[codeIndexer language] should] equal:@"Objective C"];
    });
    
    describe(@"with a C source", ^
    {
        beforeEach(^
        {
            codeIndexer = [codeIndexer initWithSource:cFilePath];
        });
        
        it(@"loads without diagnostics", ^
        {
            [[[codeIndexer diagnostics] should] beEmpty];
        });
        
        it(@"has tokens", ^
        {
            [[[[codeIndexer tokens] should] have:25] tokens];
        });
    });
});

SPEC_END
