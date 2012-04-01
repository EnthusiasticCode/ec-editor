//
//  NSString+TextMateScopeSelectorMatching.h
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TextMateScopeSelectorMatching)

/// Returns a value indicating how well the receiver is represented by the given scope selector.
/// A scope selector is a string containing dot separated scopes that can be separated by a space
/// to specify relationships. Scopes can be grouped when separated by comma.
/// For a complete specification see http://manual.macromates.com/en/scope_selectors
- (float)scoreForScopeSelector:(NSString *)scopeSelector;

@end
