//
//  ACProjectFileSpec.m
//  ArtCode
//
//  Created by Uri Baghin on 9/4/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTests.h"
#import "ACProject.h"
#import "ACProjectFolder.h"
#import "ACProjectFile.h"
#import "TMSyntaxNode.h"
#import "TMTheme.h"


SPEC_BEGIN(ACProjectFileSpec)

describe(@"A new empty ACProjectFile", ^{
  
  NSString *projectName = @"Test Project";
  __block ACProject *project = nil;
  NSString *fileName = @"Test File";
  __block ACProjectFile *file = nil;
  
  __block NSString *testQualifiedScopeIdentifier = nil;
  
  beforeAll(^{
    clearProjectsDirectory();
    [ACProject createProjectWithName:projectName labelColor:nil completionHandler:^(ACProject *createdProject) {
      project = createdProject;
    }];
    [[expectFutureValue(project) shouldEventually] beNonNil];
  });
  
  afterAll(^{
    clearProjectsDirectory();
  });
  
  beforeEach(^{
    [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile) {
      file = newFile;
    }];
    [[expectFutureValue(file) shouldEventually] beNonNil];
    __block BOOL open = NO;
    [file openWithCompletionHandler:^(BOOL success) {
      [[theValue(success) should] beYes];
      open = YES;
    }];
    [[expectFutureValue(theValue(open)) shouldEventually] beYes];
  });
  
  afterEach(^{
    [file closeWithCompletionHandler:nil];
    [file remove];
    file = nil;
    [[expectFutureValue(theValue(project.contentsFolder.children.count)) shouldEventually] beZero];
  });
  
  it(@"begins empty", ^{
    [[theValue(file.content.length) should] beZero];
  });
  
  it(@"can be changed", ^{
    NSString *testString = @"test";
    file.content = testString;
    [[file.content should] equal:testString];
    [[file.attributedContent.string should] equal:testString];
  });
  
  it(@"begins with a default theme", ^{
    [[theValue(file.theme) should] beNonNil];
  });
  
  it(@"can change it's theme", ^{
    TMTheme *newTheme = [TMTheme themeWithName:@"Amy" bundle:[NSBundle bundleForClass:[TMTheme class]]];
    file.theme = newTheme;
    [[file.theme should] equal:newTheme];
  });
  
  it(@"applies common attributes to new text", ^{
    TMTheme *newTheme = [TMTheme themeWithName:@"Amy" bundle:[NSBundle bundleForClass:[TMTheme class]]];
    NSString *testString = @"test";
    file.theme = newTheme;
    file.content = testString;
    [[file.attributedContent should] equal:[NSAttributedString.alloc initWithString:testString attributes:newTheme.commonAttributes]];
  });
  
  it(@"applies default attributes to existing text", ^{
    TMTheme *newTheme = [TMTheme themeWithName:@"Amy" bundle:[NSBundle bundleForClass:[TMTheme class]]];
    NSString *testString = @"test";
    file.content = testString;
    file.theme = newTheme;
    [[file.attributedContent should] equal:[NSAttributedString.alloc initWithString:testString attributes:newTheme.commonAttributes]];
  });
  
  it(@"has a plain text syntax by default", ^{
    [[expectFutureValue(file.syntax) shouldEventually] beNonNil];
    [[file.syntax.name should] equal:@"Plain Text"];
  });
  
  context(@"with the default syntax", ^{
    
    beforeEach(^{
      [[expectFutureValue(file.syntax) shouldEventually] beNonNil];
      [[file.syntax.name should] equal:@"Plain Text"];
    });
    
    it(@"has a text.plain scope", ^{
      [[file rac_qualifiedScopeIdentifierAtOffset:0] subscribeNext:^(id x) {
        testQualifiedScopeIdentifier = x;
      }];
      [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
      [[testQualifiedScopeIdentifier should] equal:@"text.plain"];
    });
    
    it(@"has a symbol list", ^{
      [[file.symbolList should] beNonNil];
      [[file.symbolList should] haveCountOf:0];
    });
    
    it(@"has a diagnostics list", ^{
      [[file.diagnostics should] beNonNil];
      [[file.symbolList should] haveCountOf:0];
    });
    
  });
  
  it(@"can change syntax", ^{
    file.syntax = [TMSyntaxNode syntaxWithScopeIdentifier:@"source.c"];
    [[file.syntax.name should] equal:@"C"];
    [[file rac_qualifiedScopeIdentifierAtOffset:0] subscribeNext:^(id x) {
      testQualifiedScopeIdentifier = x;
    }];
    [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
    [[testQualifiedScopeIdentifier should] equal:@"source.c"];
  });
  
  context(@"after inserting some text", ^{
    NSString *someText = 
    @"#import <stdio.h>\n\
    int testFunction(void);\n\
    <div id=\"testDIV\">blabla</div>";
    
    beforeEach(^{
      file.content = someText;
    });
    
    it(@"has a meta.paragraph.text scope", ^{
      [[file rac_qualifiedScopeIdentifierAtOffset:0] subscribeNext:^(id x) {
        testQualifiedScopeIdentifier = x;
      }];
      [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
      [[testQualifiedScopeIdentifier should] equal:@"text.plain meta.paragraph.text"];
    });
    
    context(@"and changing to C syntax", ^{
      
      beforeEach(^{
        file.syntax = [TMSyntaxNode syntaxWithScopeIdentifier:@"source.c"];
      });
      
      it(@"has a meta.preprocessor.c.include scope", ^{
        [[file rac_qualifiedScopeIdentifierAtOffset:0] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
        testQualifiedScopeIdentifier = nil;
        [[file rac_qualifiedScopeIdentifierAtOffset:7] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
      });
      
      it(@"has a keyword.control.import.include.c scope", ^{
        [[file rac_qualifiedScopeIdentifierAtOffset:1] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include keyword.control.import.include.c"];
        testQualifiedScopeIdentifier = nil;
        [[file rac_qualifiedScopeIdentifierAtOffset:6] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include keyword.control.import.include.c"];
      });
      
      it(@"has a string.quote.other.lt-gt.include.c scope", ^{
        [[file rac_qualifiedScopeIdentifierAtOffset:8] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c punctuation.definition.string.begin.c"];
        testQualifiedScopeIdentifier = nil;
        [[file rac_qualifiedScopeIdentifierAtOffset:9] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c"];
        testQualifiedScopeIdentifier = nil;
        [[file rac_qualifiedScopeIdentifierAtOffset:15] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c"];
        testQualifiedScopeIdentifier = nil;
        [[file rac_qualifiedScopeIdentifierAtOffset:16] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c punctuation.definition.string.end.c"];
        testQualifiedScopeIdentifier = nil;
      });
      
      it(@"updates the scopes after deleting characters", ^{
        NSMutableString *newContent = file.content.mutableCopy;
        [newContent deleteCharactersInRange:NSMakeRange(8, 1)];
        file.content = newContent;
        [[file rac_qualifiedScopeIdentifierAtOffset:8] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
      });
      
      it(@"updates the scopes after replacing characters", ^{
        file.content = [file.content stringByReplacingCharactersInRange:NSMakeRange(8, 1) withString:@"\""];
        [[file rac_qualifiedScopeIdentifierAtOffset:8] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.double.include.c punctuation.definition.string.begin.c"];
      });
      
      it(@"updates the scopes after inserting characters", ^{
        file.content = [file.content stringByReplacingCharactersInRange:NSMakeRange(0, 0) withString:@"/*"];
        [[file rac_qualifiedScopeIdentifierAtOffset:8] subscribeNext:^(id x) {
          testQualifiedScopeIdentifier = x;
        }];
        [[expectFutureValue(testQualifiedScopeIdentifier) shouldEventually] beNonNil];
        [[testQualifiedScopeIdentifier should] equal:@"source.c comment.block.c"];
      });
      
    });
    
  });
  
});

SPEC_END


