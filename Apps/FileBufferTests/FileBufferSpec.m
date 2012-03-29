//
//  FileBufferTests.m
//  FileBufferTests
//
//  Created by Uri Baghin on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import "CodeFile.h"

SPEC_BEGIN(FileBufferSpec)

describe(@"A FileBuffer", ^{
  
  __block CodeFile *fileBuffer;
  
  beforeEach(^{
    fileBuffer = CodeFile.alloc.init;
  });
  
  afterEach(^{
    fileBuffer = nil;
  });
  
  it(@"can be created", ^{
    [[fileBuffer should] beNonNil];
  });
  
  it(@"begins empty", ^{
    [[theValue(fileBuffer.length) should] beZero];
  });
  
  it(@"can be changed", ^{
    NSString *testString = @"test";
    [fileBuffer replaceCharactersInRange:NSMakeRange(0, 0) withString:testString];
    [[fileBuffer.string should] equal:testString];
    [[fileBuffer.attributedString.string should] equal:testString];
  });
  
  it(@"begins without default attributes", ^{
    [[theValue(fileBuffer.defaultAttributes.count) should] beZero];
  });
  
  it(@"can change it's default attributes", ^{
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttributeName"];
    fileBuffer.defaultAttributes = attributes;
    [[fileBuffer.defaultAttributes should] equal:attributes];
  });
  
  it(@"applies default attributes to text", ^{
    NSString *testString = @"test";
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttributeName"];
    fileBuffer.defaultAttributes = attributes;
    [fileBuffer replaceCharactersInRange:NSMakeRange(0, 0) withString:testString];
    [[fileBuffer.attributedString should] equal:[NSAttributedString.alloc initWithString:testString attributes:attributes]];
  });
  
  it(@"begins without file presenters", ^{
    [[theValue(fileBuffer.presenters.count) should] beZero];
  });
  
  it(@"can have file presenters added", ^{
    id mockFilePresenter = [KWMock mockForProtocol:@protocol(CodeFilePresenter)];
    [fileBuffer addPresenter:mockFilePresenter];
    [[theValue(fileBuffer.presenters.count) should] equal:theValue(1)];
    [[[fileBuffer.presenters objectAtIndex:0] should] equal:mockFilePresenter];
  });
  
  context(@"with a file presenter", ^{
    __block id mockFilePresenter;
    
    beforeEach(^{
      mockFilePresenter = [KWMock mockForProtocol:@protocol(CodeFilePresenter)];
      [mockFilePresenter stub:@selector(isEqual:) andReturn:theValue(YES)];
      [fileBuffer addPresenter:mockFilePresenter];
      [[theValue(fileBuffer.presenters.count) should] equal:theValue(1)];
      [[[fileBuffer.presenters objectAtIndex:0] should] equal:mockFilePresenter];
    });
    
    afterEach(^{
      mockFilePresenter = nil;
    });
    
    it(@"can have it removed", ^{
      [fileBuffer removePresenter:mockFilePresenter];
      [[theValue(fileBuffer.presenters.count) should] beZero];
    });
    
    it(@"calls the replace callback", ^{
      [mockFilePresenter stub:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)];
      [[mockFilePresenter should] receive:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:) withCount:1];
      [fileBuffer replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test string"];
    });
    
    it(@"calls the attribute callback", ^{
      [mockFilePresenter stub:@selector(codeFile:didReplaceCharactersInRange:withAttributedString:)];
      [mockFilePresenter stub:@selector(codeFile:didChangeAttributesInRange:)];
      [[mockFilePresenter should] receive:@selector(codeFile:didChangeAttributesInRange:) withCount:1];
      [fileBuffer replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test string"];
      [fileBuffer setAttributes:[NSDictionary dictionaryWithObject:@"testValue" forKey:@"testAttribute"] range:NSMakeRange(0, 5)];
    });
    
  });
  
});

SPEC_END
