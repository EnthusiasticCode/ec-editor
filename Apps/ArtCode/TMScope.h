//
//  CodeScope.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;

typedef enum
{
  TMScopeTypeUnknown = 0,
  TMScopeTypeMatch,
  TMScopeTypeCapture,
  TMScopeTypeSpan,
  TMScopeTypeBegin,
  TMScopeTypeEnd,
  TMScopeTypeContent,
  TMScopeTypeRoot,
} TMScopeType;

@interface TMScope : NSObject <NSCopying>

#pragma mark Scope properties

/// The identifier of the scope's class
@property (nonatomic, strong, readonly) NSString *identifier;

/// The full identifier of the scope class separated via spaces with parent scopes.
@property (nonatomic, strong, readonly) NSString *qualifiedIdentifier;

/// Returns an array representing the stack of single scopes from less to more specific.
/// This array is equivalent to separate the components separated by spaces of qualifiedIdentifier.
@property (nonatomic, strong, readonly) NSArray *identifiersStack;

/// The location of the scope
@property (nonatomic, readonly) NSUInteger location;

/// The length of the scope
@property (nonatomic, readonly) NSUInteger length;

/// The type of the scope
@property (nonatomic, readonly) TMScopeType type;

/// Spelling of the scope
@property (nonatomic, readonly) NSString *spelling;

#pragma mark Symbol list support

/// The display title of the scope
@property (nonatomic, strong, readonly) NSString *title;

/// The display icon of the scope
@property (nonatomic, strong, readonly) UIImage *icon;

/// The level of indentation in the symbol list
@property (nonatomic, readonly) NSUInteger indentation;

/// Whether or not the scope serves as a separator
@property (nonatomic, readonly, getter = isSeparator) BOOL separator;

@end

