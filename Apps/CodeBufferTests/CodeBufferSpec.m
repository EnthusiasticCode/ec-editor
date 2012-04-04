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
#import "TMScope.h"
#import "TMCompletions.h"

// Redefine the default timeout because my iMac is so slow
#undef kKW_DEFAULT_PROBE_TIMEOUT
#define kKW_DEFAULT_PROBE_TIMEOUT 10

SPEC_BEGIN(CodeBufferSpec)

describe(@"A CodeBuffer", ^{
  
  context(@"without fileURL or index", ^{
    __block CodeBuffer *codeBuffer;
    __block TMScope *testScope;
    
    beforeEach(^{
      codeBuffer = CodeBuffer.alloc.init;
    });
    
    afterEach(^{
      codeBuffer = nil;
      testScope = nil;
    });
    
    it(@"can be created", ^{
      [[codeBuffer should] beNonNil];
    });
    
    it(@"has a plain text syntax by default", ^{
      [[expectFutureValue(codeBuffer.syntax) shouldEventually] beNonNil];
      [[codeBuffer.syntax.name should] equal:@"Plain Text"];
    });
    
    context(@"with the default syntax", ^{
      
      beforeEach(^{
        [[expectFutureValue(codeBuffer.syntax) shouldEventually] beNonNil];
        [[codeBuffer.syntax.name should] equal:@"Plain Text"];
      });
      
      it(@"has a text.plain scope", ^{
        [codeBuffer scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.identifier should] equal:@"text.plain"];
      });
      
      it(@"has a symbol list", ^{
        [[codeBuffer.symbolList should] beNonNil];
        [[codeBuffer.symbolList should] haveCountOf:0];
      });
      
      it(@"has a diagnostics list", ^{
        [[codeBuffer.diagnostics should] beNonNil];
        [[codeBuffer.symbolList should] haveCountOf:0];
      });
      
    });
    
    it(@"can change syntax", ^{
      codeBuffer.syntax = [TMSyntaxNode syntaxWithScopeIdentifier:@"source.c"];
      [[codeBuffer.syntax.name should] equal:@"C"];
      [codeBuffer scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
        testScope = scope;
      }];
      [[expectFutureValue(testScope) shouldEventually] beNonNil];
      [[testScope.identifier should] equal:@"source.c"];
    });
    
    context(@"after inserting some text", ^{
      NSString *someText = 
      @"#import <stdio.h>\n\
      int testFunction(void);\n\
      <div id=\"testDIV\">blabla</div>";
      
      beforeEach(^{
        [codeBuffer replaceCharactersInRange:NSMakeRange(0, 0) withString:someText];
      });
      
      it(@"has a meta.paragraph.text scope", ^{
        [codeBuffer scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.identifier should] equal:@"meta.paragraph.text"];
      });
      
      context(@"and changing to C syntax", ^{
        
        beforeEach(^{
          codeBuffer.syntax = [TMSyntaxNode syntaxWithScopeIdentifier:@"source.c"];
        });
        
        it(@"has a meta.preprocessor.c.include scope", ^{
          [codeBuffer scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
            testScope = scope;
          }];
          [[expectFutureValue(testScope) shouldEventually] beNonNil];
          [[testScope.identifier should] equal:@"meta.preprocessor.c.include"];
        });
        
      });
      
    });
    
  });
  
});

SPEC_END
