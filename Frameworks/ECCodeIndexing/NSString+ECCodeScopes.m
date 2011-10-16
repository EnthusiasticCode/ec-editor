//
//  NSString+ECCodeScopes.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+ECCodeScopes.h"

static NSString * const scopeSeparator = @".";

@implementation NSString (ECCodeScopes)

- (BOOL)containsScope:(NSString *)scopeIdentifier
{
    NSArray *selfComponents = [self componentsSeparatedByString:scopeSeparator];
    NSArray *otherComponents = [scopeIdentifier componentsSeparatedByString:scopeSeparator];
    NSUInteger componentIndex = 0;
    for (NSString *component in selfComponents)
    {
        if (![component isEqualToString:[otherComponents objectAtIndex:componentIndex]])
            return NO;
        ++componentIndex;
    }
    return YES;
}

@end
