//
//  TMSymbol.m
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMSymbol.h"
#import "TMScope.h"
#import "TMPreference.h"

static NSString *(^_identityTransformation)(NSString *) = ^(NSString *string){
  return string;
};
static NSUInteger (^_indentationForRawTitle)(NSString *) = ^(NSString *rawTitle){
  NSUInteger titleLength = [rawTitle length];
  NSUInteger indentation = 0;
  for (; indentation < titleLength; ++indentation)
  {
    if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[rawTitle characterAtIndex:indentation]])
      break;
  }
  return indentation;
};
static UIImage *_TMScopeBlankImage = nil;


@interface TMSymbol ()

- (NSString *)_rawTitle;

@end

@implementation TMSymbol {
  TMScope *_scope;
  NSString *(^_transformation)(NSString *);
  NSNumber *_separator;
}

@synthesize icon = _icon;

- (NSString *)_rawTitle {
  if (!_transformation) {
    _transformation = [TMPreference preferenceValueForKey:TMPreferenceSymbolTransformationKey qualifiedIdentifier:self.qualifiedIdentifier] ?: (id)_identityTransformation;
  }
  return _transformation(_scope.spelling);
}

- (NSString *)title {
  NSString *rawTitle = [self _rawTitle];
  NSUInteger indentation = _indentationForRawTitle(rawTitle);
  return indentation ? [rawTitle substringFromIndex:indentation] : rawTitle;
}

- (NSUInteger)indentation {
  NSString *rawTitle = [self _rawTitle];
  return _indentationForRawTitle(rawTitle);
}

- (UIImage *)icon {
  if (!_icon) {
    _icon = [TMPreference preferenceValueForKey:TMPreferenceSymbolIconKey qualifiedIdentifier:self.qualifiedIdentifier];
    if (!_icon) {
      _icon = _TMScopeBlankImage ?: (_TMScopeBlankImage = [UIImage new]);
    }
  }
  return _icon;
}

- (BOOL)isSeparator {
  if (!_separator) {
    _separator = [TMPreference preferenceValueForKey:TMPreferenceSymbolIsSeparatorKey qualifiedIdentifier:self.qualifiedIdentifier];
    if (!_separator) {
      _separator = [NSNumber numberWithBool:NO];
    }
  }
  return [_separator boolValue];
}

- (NSString *)qualifiedIdentifier {
  return _scope.qualifiedIdentifier;
}

- (NSRange)range {
  return NSMakeRange(_scope.location, _scope.length);
}

- (id)initWithScope:(TMScope *)scope
{
  ASSERT(scope);
  self = [super init];
  if (!self)
    return nil;
  _scope = scope;
  return self;
}

@end
