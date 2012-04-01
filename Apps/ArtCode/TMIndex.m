//
//  CodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TMIndex.h"
#import "TMUnit+Internal.h"
#import "TMSyntaxNode.h"

static NSMutableDictionary *_extensionClasses;

@implementation TMIndex {
  NSMutableDictionary *_extensions;
}

+ (void)registerExtension:(Class)extensionClass forKey:(id)key
{
  if (!_extensionClasses)
    _extensionClasses = [[NSMutableDictionary alloc] init];
  [_extensionClasses setObject:extensionClass forKey:key];
}

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  _extensions = [NSMutableDictionary dictionaryWithCapacity:[_extensionClasses count]];
  [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    id extension = [[obj alloc] init];
    if (!extension)
      return;
    [_extensions setObject:extension forKey:key];
  }];
  return self;
}

- (id)extensionForKey:(id)key
{
  return [_extensions objectForKey:key];
}

@end
