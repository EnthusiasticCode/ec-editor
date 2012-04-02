//
//  CodeBuffer.m
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CodeBuffer.h"
#import "TMUnit.h"

@interface CodeBuffer ()

@property (nonatomic, strong) TMUnit *_codeUnit;

@end

@implementation CodeBuffer

@synthesize _codeUnit = __codeUnit;

#pragma mark - KVO

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  return [NSSet setWithObject:[@"_codeUnit." stringByAppendingString:key]];
}

#pragma mark - FileBuffer

- (id)initWithFileURL:(NSURL *)fileURL {
  return [self initWithFileURL:fileURL index:nil];
}

#pragma mark - Public Methods

- (TMSyntaxNode *)syntax {
  return __codeUnit.syntax;
}

- (void)setSyntax:(TMSyntaxNode *)syntax {
  [__codeUnit setSyntax:syntax];
}

- (NSArray *)symbolList {
  return __codeUnit.symbolList;
}

- (NSArray *)diagnostics {
  return __codeUnit.diagnostics;
}

- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index {
  self = [super initWithFileURL:fileURL];
  if (!self) {
    return nil;
  }
  __codeUnit = [TMUnit.alloc initWithFileBuffer:self fileURL:fileURL index:index];
  ASSERT(__codeUnit);
  return self;
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(TMScope *scope))completionHandler {
  [__codeUnit scopeAtOffset:offset withCompletionHandler:completionHandler];
}

- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(id<TMCompletionResultSet>))completionHandler {
  [__codeUnit completionsAtOffset:offset withCompletionHandler:completionHandler];
}

@end
