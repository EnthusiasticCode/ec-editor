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

@interface TMScope : NSObject

#pragma mark Scope properties

// The identifier of the scope's class
@property (nonatomic, strong, readonly) NSString *identifier;

// The full identifier of the scope class separated via spaces with parent scopes.
@property (nonatomic, strong, readonly) NSString *qualifiedIdentifier;

// Returns an array representing the stack of single scopes from less to more specific.
// This array is equivalent to separate the components separated by spaces of qualifiedIdentifier.
@property (nonatomic, strong, readonly) NSArray *identifiersStack;

// The location of the scope
@property (nonatomic, readonly) NSUInteger location;

// The length of the scope
@property (nonatomic, readonly) NSUInteger length;

// The type of the scope
@property (nonatomic, readonly) TMScopeType type;

// Spelling of the scope
@property (nonatomic, readonly) NSString *spelling;

@end

