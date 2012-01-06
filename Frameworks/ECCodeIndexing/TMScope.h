//
//  ECCodeScope.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMScope : NSObject
/// The identifier of the scope's class
@property (nonatomic, strong) NSString *identifier;
/// The offset of the scope's beginning from the end of it's previous sibling
@property (nonatomic) NSInteger offset;
/// The length of the scope
@property (nonatomic) NSUInteger length;
/// The spelling of the scope
@property (nonatomic, readonly) NSString *spelling;
/// The base string containing the scope
@property (nonatomic, strong) NSString *baseString;
/// The parent scope, if one exists
@property (nonatomic, weak) TMScope *parent;
/// The children scopes, if any exist
@property (nonatomic, readonly) NSArray *children;
/// Creates a new root scope with the given identifier and base string
- (id)initWithIdentifier:(NSString *)identifier string:(NSString *)string;
/// Adds a new child scope with the given identifier
- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier;
/// Retrieve the the offset of the scope relative to the base string
/// A generation must be provided to aid in caching. The counter must be increased every time the baseString is modified.
/// The generation must be greater or equal to 1, passing 0 will give the cached value regardless.
- (NSUInteger)baseOffsetForGeneration:(NSUInteger)generation;
@end

