//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeIndex;

//! Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject
@property (nonatomic, readonly, retain) ECCodeIndex *index;
@property (nonatomic, readonly, retain) NSURL *url;
@property (nonatomic, readonly, retain) NSString *language;
- (NSArray *)completionsWithSelection:(NSRange)selection;
- (NSArray *)diagnostics;
- (NSArray *)fixIts;
- (NSArray *)tokensInRange:(NSRange)range;
- (NSArray *)tokens;
@end
