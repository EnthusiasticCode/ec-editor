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
  
  it(@"can be created", ^{
    CodeFile *codeFile = CodeFile.alloc.init;
    [[codeFile should] beNonNil];
  });
  
});

SPEC_END