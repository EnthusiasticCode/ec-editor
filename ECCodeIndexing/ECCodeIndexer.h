//
//  ECCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeIndexerDelegate.h"


/*! Superclass of all code indexers. Implement language agnostic functionality here.
 *
 * Code indexers encapsulate interaction with parsing and indexing libraries to provide language related functionality such as syntax aware highlighting, hyperlinking and completions.
 */
@interface ECCodeIndexer : NSObject {

}
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) id<ECCodeIndexerDelegate> delegate;
@property (nonatomic, readonly, retain) NSArray *diagnostics;
- (id)initWithSource:(NSString *)source;
- (NSRange)completionRange;
- (NSArray *)completions;
- (NSArray *)diagnostics;
- (NSArray *)tokensForRange:(NSRange)range;
- (NSArray *)tokens;

@end
