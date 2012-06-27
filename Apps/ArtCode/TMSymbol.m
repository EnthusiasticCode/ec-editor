//
//  TMSymbol.m
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMSymbol.h"

@implementation TMSymbol

@synthesize qualifiedIdentifier = _qualifiedIdentifier, title = _title, icon = _icon, range = _range, indentation = _indentation, separator = _separator;

- (id)initWithQualifiedIdentifier:(NSString *)qualifiedIdentifier title:(NSString *)title icon:(UIImage *)icon range:(NSRange)range
{
  ASSERT(qualifiedIdentifier && title && icon);
  self = [super init];
  if (!self)
    return nil;
  // Get indentation level and modify title
  NSUInteger titleLength = [_title length];
  for (; _indentation < titleLength; ++_indentation)
  {
    if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[title characterAtIndex:_indentation]])
      break;
  }
  _qualifiedIdentifier = qualifiedIdentifier;
  _title = _indentation ? [title substringFromIndex:_indentation] : title;
  _icon = icon;
  _range = range;
  return self;
}

@end
