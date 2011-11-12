//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeUnit, ECAttributedUTF8FileBuffer;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject

/// Code unit creation
/// If the scope is not specified, it will be detected automatically
- (ECCodeUnit *)codeUnitForFileBuffer:(ECAttributedUTF8FileBuffer *)fileBuffer scope:(NSString *)scope;

@end
