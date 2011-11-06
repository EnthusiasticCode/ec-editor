//
//  TMScope.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMScope : NSObject

/// The string containing the scope
@property (nonatomic, strong) NSString *containingString;
/// The identifier of the scope's class
@property (nonatomic, strong) NSString *identifier;
/// The range of the scope within the containingString
@property (nonatomic) NSRange range;
/// The spelling of the scope as it appears in the containingString
@property (nonatomic, readonly) NSString *spelling;
/// The parent scope, if one exists
@property (nonatomic, weak) TMScope *parent;
/// The children scopes, if any exist
@property (nonatomic, strong) NSArray *children;
/// Identifiers of the scope and all ancestor scopes
- (NSArray *)identifiersStack;

@end
