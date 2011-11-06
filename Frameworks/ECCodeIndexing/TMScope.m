//
//  TMScope.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

@implementation TMScope

@synthesize containingString = _containingString;
@synthesize identifier = _identifier;
@synthesize range = _range;
@synthesize parent = _parent;
@synthesize children = _children;

- (NSString *)spelling
{
    return [self.containingString substringWithRange:self.range];
}

+ (NSSet *)keyPathsForValuesAffectingSpelling
{
    return [NSSet setWithObjects:@"containingString", @"range", nil];
}

- (NSArray *)identifiersStack
{
    NSMutableArray *identifiersStack = [NSMutableArray array];
    TMScope *currentScope = self;
    while (currentScope)
    {
        [identifiersStack insertObject:currentScope.identifier atIndex:0];
        currentScope = currentScope.parent;
    }
    return identifiersStack;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%d,%d} : %@ (%d children)", [self range].location, [self range].length, [self identifier], [[self children] count]];
}

@end
