//
//  CodeScope.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

@class TMSyntaxNode;

@interface TMScope ()

/// The identifier of the scope's class
@property (nonatomic, strong) NSString *identifier;

/// The syntax node that created the scope
@property (nonatomic, strong) TMSyntaxNode *syntaxNode;

/// The location of the scope's start relative to the parent's start
@property (nonatomic) NSUInteger location;

/// The length of the scope
@property (nonatomic) NSUInteger length;

/// The parent scope, if one exists
@property (nonatomic, weak) TMScope *parent;

/// Adds a new child scope with the given identifier.
- (TMScope *)newChildScope;

/// Return a number indicating how much a scope selector array matches the search.
/// A scope selector array is an array of strings defining a context of scopes where
/// a scope must be child of the previous scope in the array.
- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search;

/// Returns a number indicating how much the receiver matches the search scope selector.
/// A scope selector reference is a string containing a single scope context (ie: scopes divided by spaces).
- (float)_scoreForSearchScope:(NSString *)search;

@end

