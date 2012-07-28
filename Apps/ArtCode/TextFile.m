//
//  TextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextFile.h"

@implementation TextFile

#pragma mark - UIDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  if (![contents isKindOfClass:[NSData class]]) {
    return NO;
  }
  self.content = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
  return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  return [self.content dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - Public Methods

- (void)setContent:(NSString *)content {
  if (content == _content) {
    return;
  }
  _content = content;
  [self updateChangeCount:UIDocumentChangeDone];
}

@end
