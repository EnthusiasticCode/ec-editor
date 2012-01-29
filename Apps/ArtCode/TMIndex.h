//
//  ECCodeIndexing.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMUnit, ECFileBuffer;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface TMIndex : NSObject

/// Code unit creation
/// If the scope is not specified, it will be detected automatically
- (TMUnit *)codeUnitForFileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier;

@end
