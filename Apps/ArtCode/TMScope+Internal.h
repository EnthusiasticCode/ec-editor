//
//  CodeScope.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

@class TMSyntaxNode, OnigRegexp;
@protocol TMScopeDelegate;

/// Options to specify the behaviour of the scope query methods. These are not cumulative.
typedef enum
{
    /// The query will match only scopes that fully contain the queried range or offset
    TMScopeQueryContainedOnly = 0,
    /// The query will also match scopes that start adjacent to the queried range or offset
    TMScopeQueryAdjacentStart,
    /// The query will also match scopes that end adjacent to the queried range or offset
    TMScopeQueryAdjacentEnd,
} TMScopeQueryOptions;

@interface TMScope ()

/// The syntax node that created the scope
@property (nonatomic, strong, readonly) TMSyntaxNode *syntaxNode;

/// Delegate for callbacks, only applicable for root scopes
@property (nonatomic, weak) id<TMScopeDelegate>delegate;

/// Cached end regexp for scopes with a span syntax node
@property (nonatomic, strong) OnigRegexp *endRegexp;

/// The length of the scope
@property (nonatomic) NSUInteger length;

/// The parent scope, if one exists
@property (nonatomic, weak, readonly) TMScope *parent;

/// The children scopes, if any exist
@property (nonatomic, strong, readonly) NSArray *children;

/// Adds a new child scope with the given properties
- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode location:(NSUInteger)location type:(TMScopeType)type;

/// Creates a new root scope
+ (TMScope *)newRootScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode;

/// Method to query the scope tree. Can only be called on root scopes
- (NSMutableArray *)scopeStackAtOffset:(NSUInteger)offset options:(TMScopeQueryOptions)options;

/// Methods to apply changes to the scope tree. Can only be called on root scopes
- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange;
- (void)removeChildScopesInRange:(NSRange)range;

@end

@protocol TMScopeDelegate <NSObject>

- (void)scope:(TMScope *)scope didAddScope:(TMScope *)scope;
- (void)scope:(TMScope *)scope willRemoveScope:(TMScope *)scope;

@end