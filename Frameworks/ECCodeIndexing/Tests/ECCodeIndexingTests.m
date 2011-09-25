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

describe(@"A code index",^{
    __block ECCodeIndex *codeIndex;
    __block ECCodeUnit *cCodeUnit;
    __block NSURL *cFileURL;
    __block NSURL *invalidFileURL;
    beforeAll(^{
        NSString *cFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"];
        NSString *invalidFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"thisfiledoesnotexist.c"];
        cFileURL = [[NSURL alloc] initFileURLWithPath:cFilePath];
        invalidFileURL = [[NSURL alloc] initFileURLWithPath:invalidFilePath];
    });
    
    afterAll(^{
        [cFileURL release];
        [invalidFileURL release];
    });
    
    beforeEach(^{
        codeIndex = [[ECCodeIndex alloc] init];
        [@"" writeToURL:cFileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    });
    
    afterEach(^{
        [codeIndex release];
    });
    
    it(@"should support at least 4 languages", ^{
        [[[ECCodeIndex should] haveAtLeast:4] supportedLanguages];
    });
    
    it(@"doesn't create an invalid code unit", ^{
        [[codeIndex unitWithFileURL:invalidFileURL] shouldBeNil];
    });
    
    it(@"creates a valid code unit", ^{
        [[codeIndex unitWithFileURL:cFileURL] shouldNotBeNil];
    });
    
    describe(@"creates a code unit from a C file which", ^{
        beforeEach(^{
            [@"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" writeToURL:cFileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
            cCodeUnit = [[codeIndex unitWithFileURL:cFileURL] retain];
        });
        
        afterEach(^{
            [cCodeUnit release];
        });
        
        it(@"loads without diagnostics", ^{
            [[[cCodeUnit diagnostics] should] beEmpty];
        });
        
        it(@"has 25 tokens", ^{
            [[[cCodeUnit should] have:25] tokensInRange:NSMakeRange(0, 79) withCursors:NO];
        });
        
        it(@"has 4 tokens between the 8th and 18th character", ^{
            [[[cCodeUnit should] have:6] tokensInRange:NSMakeRange(8, 10) withCursors:NO];
        });
        
        it(@"has at least 400 completions", ^{
            [[[cCodeUnit completionsAtOffset:57] should] haveCountOfAtLeast:400];
        });
        
        it(@"uses file coordination to reparse the source automatically", ^{
            // This test does not currently work because the simulator doesn't implement file coordination properly (beta 7)
            [[[cCodeUnit should] have:25] tokensInRange:NSMakeRange(0, 79) withCursors:NO];
            [@"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world %d\", 1); }" writeToURL:cFileURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
//            [cCodeUnit performSelector:@selector(reparseSourceFiles)];
            [[[cCodeUnit should] have:27] tokensInRange:NSMakeRange(0, 84) withCursors:NO];
        });
    });
});

SPEC_END