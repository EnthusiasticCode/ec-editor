//
//  CodeScope.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMScope : NSObject
/// The identifier of the scope's class
@property (nonatomic, strong) NSString *identifier;
/// The location of the scope's start relative to the parent's start
@property (nonatomic) NSUInteger location;
/// The length of the scope
@property (nonatomic) NSUInteger length;
/// The parent scope, if one exists
@property (nonatomic, weak) TMScope *parent;
/// The children scopes, if any exist
@property (nonatomic, strong, readonly) NSMutableArray *children;
/// Adds a new child scope with the given identifier
- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier;
@end

