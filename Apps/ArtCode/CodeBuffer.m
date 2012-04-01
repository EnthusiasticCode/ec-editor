//
//  CodeBuffer.m
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CodeBuffer.h"
#import "TMUnit.h"


@implementation CodeBuffer {
  TMUnit *_codeUnit;
}

#pragma mark - FileBuffer

- (id)initWithFileURL:(NSURL *)fileURL {
  return [self initWithFileURL:fileURL index:nil];
}

#pragma mark - Public Methods

- (TMSyntaxNode *)syntax {
  return _codeUnit.syntax;
}

- (void)setSyntax:(TMSyntaxNode *)syntax {
  [_codeUnit setSyntax:syntax];
}

- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index {
  self = [super initWithFileURL:fileURL];
  if (!self) {
    return nil;
  }
  _codeUnit = [TMUnit.alloc initWithFileBuffer:self fileURL:fileURL index:index];
  return self;
}

@end
