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
    /// The query will match scopes to the right of the range or offset
    TMScopeQueryRight = 1 << 0,
    /// The query will match scopes to the left of the range or offset
    TMScopeQueryLeft = 1 << 1,
    /// The query will only match scopes to the left or right if they're missing the end or begin respectively
    TMScopeQueryOpenOnly = 1 << 2,
} TMScopeQueryOptions;

/// Scope flags. Not all flags are valid for all scope types
typedef enum
{
    TMScopeHasBegin = 1 << 0,
    TMScopeHasEnd = 1 << 1,
    TMScopeHasBeginScope = 1 << 2,
    TMScopeHasEndScope = 1 << 3,
    TMScopeHasContentScope = 1 << 4,
} TMScopeFlags;

@interface TMScope ()

/// The syntax node that created the scope
@property (nonatomic, strong, readonly) TMSyntaxNode *syntaxNode;

/// Delegate for callbacks, only applicable for root scopes
@property (nonatomic, weak) id<TMScopeDelegate>delegate;

/// Cached end regexp for scopes with a span syntax node
@property (nonatomic, strong) OnigRegexp *endRegexp;

/// The length of the scope
@property (nonatomic) NSUInteger length;

/// Flags for additional type specific attributes
@property (nonatomic) TMScopeFlags flags;

/// The parent scope, if one exists
@property (nonatomic, weak, readonly) TMScope *parent;

/// The children scopes, if any exist
@property (nonatomic, strong, readonly) NSArray *children;

/// Adds a new child scope with the given properties
- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode location:(NSUInteger)location type:(TMScopeType)type;

/// Creates a new root scope
+ (TMScope *)newRootScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode;

/// Removes the scope from it's parent's children
- (void)removeFromParent;

/// Method to query the scope tree. Can only be called on root scopes
- (NSMutableArray *)scopeStackAtOffset:(NSUInteger)offset options:(TMScopeQueryOptions)options;

/// Methods to apply changes to the scope tree. Can only be called on root scopes
- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange;
- (void)removeChildScopesInRange:(NSRange)range;
/// Attempts to merge a broken scope tree at the specified offset. Returns YES if successful
- (BOOL)attemptMergeAtOffset:(NSUInteger)offset;

@end

@protocol TMScopeDelegate <NSObject>

- (void)scope:(TMScope *)scope didAddScope:(TMScope *)scope;
- (void)scope:(TMScope *)scope willRemoveScope:(TMScope *)scope;

@end