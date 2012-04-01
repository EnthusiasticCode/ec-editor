//
//  CodeBufferTests.m
//  CodeBufferTests
//
//  Created by Uri Baghin on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import "CodeBuffer.h"
#import "TMSyntaxNode.h"

// Redefine the default timeout because my iMac is so slow
#undef kKW_DEFAULT_PROBE_TIMEOUT
#define kKW_DEFAULT_PROBE_TIMEOUT 10

SPEC_BEGIN(CodeBufferSpec)

describe(@"A CodeBuffer", ^{
  
  context(@"without fileURL or index", ^{
    __block CodeBuffer *codeBuffer;
    
    beforeEach(^{
      codeBuffer = CodeBuffer.alloc.init;
    });
    
    afterEach(^{
      codeBuffer = nil;
    });

    it(@"can be created", ^{
      [[codeBuffer should] beNonNil];
    });
    
    it(@"has a plain text syntax by default", ^{
      [[expectFutureValue(codeBuffer.syntax) shouldEventually] beNonNil];
      [[codeBuffer.syntax.name should] equal:@"Plain Text"];
    });
    
  });
  
});

SPEC_END
