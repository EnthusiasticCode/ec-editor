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
#import "TMScope.h"


SPEC_BEGIN(ACProjectFileSpec)

describe(@"A new empty ACProjectFile", ^{
  
  NSString *projectName = @"Test Project";
  __block ACProject *project = nil;
  NSString *fileName = @"Test File";
  __block ACProjectFile *file = nil;
  
  __block TMScope *testScope = nil;
  
  beforeAll(^{
    clearProjectsDirectory();
    [ACProject createProjectWithName:projectName labelColor:nil completionHandler:^(ACProject *createdProject, NSError *error) {
      [error shouldBeNil];
      project = createdProject;
    }];
    [[expectFutureValue(project) shouldEventually] beNonNil];
  });
  
  afterAll(^{
    clearProjectsDirectory();
  });
  
  beforeEach(^{
    [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
      [error shouldBeNil];
      file = newFile;
    }];
    [[expectFutureValue(file) shouldEventually] beNonNil];
  });
  
  afterEach(^{
    [file remove];
    [[theValue(project.contentsFolder.children.count) should] beZero];
  });
  
  it(@"begins empty", ^{
    [[theValue(file.length) should] beZero];
  });
  
  it(@"can be changed", ^{
    NSString *testString = @"test";
    [file replaceCharactersInRange:NSMakeRange(0, 0) withString:testString];
    [[file.string should] equal:testString];
    [[file.attributedString.string should] equal:testString];
  });
  
//  it(@"begins without default attributes", ^{
//    [[theValue(file.defaultAttributes.count) should] beZero];
//  });
//  
//  it(@"can change it's default attributes", ^{
//    NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttributeName"];
//    file.defaultAttributes = attributes;
//    [[file.defaultAttributes should] equal:attributes];
//  });
//  
//  it(@"applies default attributes to new text", ^{
//    NSString *testString = @"test";
//    NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttributeName"];
//    file.defaultAttributes = attributes;
//    [file replaceCharactersInRange:NSMakeRange(0, 0) withString:testString];
//    [[file.attributedString should] equal:[NSAttributedString.alloc initWithString:testString attributes:attributes]];
//  });
//  
//  it(@"applies default attributes to existing text", ^{
//    NSString *testString = @"test";
//    NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttributeName"];
//    [file replaceCharactersInRange:NSMakeRange(0, 0) withString:testString];
//    file.defaultAttributes = attributes;
//    [[file.attributedString should] equal:[NSAttributedString.alloc initWithString:testString attributes:attributes]];
//  });
  
  it(@"begins without file presenters", ^{
    [[theValue(file.presenters.count) should] beZero];
  });
  
  it(@"can have file presenters added", ^{
    id mockFilePresenter = [KWMock mockForProtocol:@protocol(ACProjectFilePresenter)];
    [file addPresenter:mockFilePresenter];
    [[theValue(file.presenters.count) should] equal:theValue(1)];
    [[[file.presenters objectAtIndex:0] should] equal:mockFilePresenter];
  });
  
  context(@"with a file presenter", ^{
    __block id mockFilePresenter;
    
    beforeEach(^{
      mockFilePresenter = [KWMock mockForProtocol:@protocol(ACProjectFilePresenter)];
      [mockFilePresenter stub:@selector(isEqual:) andReturn:theValue(YES)];
      [file addPresenter:mockFilePresenter];
      [[theValue(file.presenters.count) should] equal:theValue(1)];
      [[[file.presenters objectAtIndex:0] should] equal:mockFilePresenter];
    });
    
    afterEach(^{
      mockFilePresenter = nil;
    });
    
    it(@"can have it removed", ^{
      [file removePresenter:mockFilePresenter];
      [[theValue(file.presenters.count) should] beZero];
    });
    
    it(@"calls the replace callback", ^{
      [mockFilePresenter stub:@selector(projectFile:didReplaceCharactersInRange:withAttributedString:)];
      [[mockFilePresenter should] receive:@selector(projectFile:didReplaceCharactersInRange:withAttributedString:) withCount:1];
      [file replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test string"];
    });
    
    it(@"calls the attribute callback", ^{
      [mockFilePresenter stub:@selector(projectFile:didReplaceCharactersInRange:withAttributedString:)];
      [mockFilePresenter stub:@selector(projectFile:didChangeAttributesInRange:)];
      [[mockFilePresenter should] receive:@selector(projectFile:didChangeAttributesInRange:) withCount:1];
      [file replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test string"];
      [file addAttributes:[NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttribute"] range:NSMakeRange(0, 5)];
    });
    
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
      [file scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
        testScope = scope;
      }];
      [[expectFutureValue(testScope) shouldEventually] beNonNil];
      [[testScope.identifier should] equal:@"text.plain"];
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
    [file scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
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
      [file replaceCharactersInRange:NSMakeRange(0, 0) withString:someText];
    });
    
    it(@"has a meta.paragraph.text scope", ^{
      [file scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
        testScope = scope;
      }];
      [[expectFutureValue(testScope) shouldEventually] beNonNil];
      [[testScope.qualifiedIdentifier should] equal:@"text.plain meta.paragraph.text"];
    });
    
    context(@"and changing to C syntax", ^{
      
      beforeEach(^{
        file.syntax = [TMSyntaxNode syntaxWithScopeIdentifier:@"source.c"];
      });
      
      it(@"has a meta.preprocessor.c.include scope", ^{
        [file scopeAtOffset:0 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
        testScope = nil;
        [file scopeAtOffset:7 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
      });
      
      it(@"has a keyword.control.import.include.c scope", ^{
        [file scopeAtOffset:1 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include keyword.control.import.include.c"];
        testScope = nil;
        [file scopeAtOffset:6 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include keyword.control.import.include.c"];
      });
      
      it(@"has a string.quote.other.lt-gt.include.c scope", ^{
        [file scopeAtOffset:8 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c punctuation.definition.string.begin.c"];
        testScope = nil;
        [file scopeAtOffset:9 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c"];
        testScope = nil;
        [file scopeAtOffset:15 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c"];
        testScope = nil;
        [file scopeAtOffset:16 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.other.lt-gt.include.c punctuation.definition.string.end.c"];
        testScope = nil;
      });
      
      it(@"updates the scopes after deleting characters", ^{
        [file replaceCharactersInRange:NSMakeRange(8, 1) withString:nil];
        [file scopeAtOffset:8 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include"];
      });
      
      it(@"updates the scopes after replacing characters", ^{
        [file replaceCharactersInRange:NSMakeRange(8, 1) withString:@"\""];
        [file scopeAtOffset:8 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c meta.preprocessor.c.include string.quoted.double.include.c punctuation.definition.string.begin.c"];
      });
      
      it(@"updates the scopes after inserting characters", ^{
        [file replaceCharactersInRange:NSMakeRange(0, 0) withString:@"/*"];
        [file scopeAtOffset:8 withCompletionHandler:^(TMScope *scope) {
          testScope = scope;
        }];
        [[expectFutureValue(testScope) shouldEventually] beNonNil];
        [[testScope.qualifiedIdentifier should] equal:@"source.c comment.block.c"];
      });
      
    });
    
  });
  
});

SPEC_END


