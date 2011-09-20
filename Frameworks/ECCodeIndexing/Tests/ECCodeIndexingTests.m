//
//  ECCodeIndexingTests.m
//  ECCodeIndexingTests
//
//  Created by Uri Baghin on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Kiwi.h"

#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>

SPEC_BEGIN(ECCodeIndexingSpec)

describe(@"A code index",^
{
    __block ECCodeIndex *codeIndex;
    __block ECCodeUnit *cCodeUnit;
    __block NSURL *cFileURL;
    __block NSURL *invalidFileURL;
    beforeAll(^
              {
                  NSString *cFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"];
                  NSString *invalidFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"thisfiledoesnotexist"];
                  cFileURL = [[NSURL alloc] initFileURLWithPath:cFilePath];
                  invalidFileURL = [[NSURL alloc] initFileURLWithPath:invalidFilePath];
                  [@"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" writeToURL:cFileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
              });
    
    afterAll(^
             {
                 [cFileURL release];
                 [invalidFileURL release];
             });
    
    beforeEach(^
               {
                   codeIndex = [[ECCodeIndex alloc] init];
               });
    
    afterEach(^
              {
                  [codeIndex release];
              });
    
    it(@"has a language to extension mapping dictionary", ^
       {
           [[[codeIndex should] have:4] languageToExtensionMap];
       });
    
    it(@"has an extension to language mapping dictionary", ^
       {
           [[[codeIndex should] have:5] extensionToLanguageMap];
       });
    
    it(@"maps extensions to languages", ^
       {
           [[[codeIndex languageForExtension:@"m"] should] equal:@"Objective C"];
       });
    
    it(@"maps languages to extensions", ^
       {
           [[[codeIndex extensionForLanguage:@"Objective C"] should] equal:@"m"];
       });
    
    it(@"doesn't create an invalid code unit", ^
       {
           [[codeIndex unitForURL:invalidFileURL] shouldBeNil];
       });
    
    it(@"creates a valid code unit", ^
       {
           [[codeIndex unitForURL:cFileURL] shouldNotBeNil];
       });
    
    describe(@"creates a code unit which", ^
             {
                 beforeEach(^
                            {
                                cCodeUnit = [[codeIndex unitForURL:cFileURL] retain];
                            });
                 
                 afterEach(^
                           {
                               [cCodeUnit release];
                           });
                 
                 it(@"detects the language based on source", ^
                    {
                        [[cCodeUnit.language should] equal:@"C"];
                    });
                 
                 it(@"loads without diagnostics", ^
                    {
                        [[[cCodeUnit diagnostics] should] beEmpty];
                    });
                 
                 it(@"has 25 tokens", ^
                    {
                        [[[cCodeUnit should] have:25] tokens];
                    });
                 
                 it(@"has 4 tokens between the 8th and 18th character", ^
                    {
                        [[[cCodeUnit should] have:6] tokensInRange:NSMakeRange(8, 10)];
                    });
                 
                 it(@"has at least 400 completions", ^
                    {
                        [[[cCodeUnit completionsWithSelection:NSMakeRange(57, 0)] should] haveCountOfAtLeast:400];
                    });
             });
});

SPEC_END