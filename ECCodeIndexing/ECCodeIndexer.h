//
//  ECCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


//TODO: turn this into a class cluster: http://seanmurph.com/weblog/make-your-own-abstract-factory-class-cluster-in-objective-c/

/*! Superclass of all code indexers. Implement language agnostic functionality here.
 *
 * Code indexers encapsulate interaction with parsing and indexing libraries to provide language related functionality such as syntax aware highlighting, hyperlinking and completions.
 */
@interface ECCodeIndexer : NSObject {

}
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSString *delegateTextKey;
@property (nonatomic, readonly, retain) NSArray *diagnostics;
- (id)initWithSource:(NSString *)source;
- (NSRange)completionRangeWithSelection:(NSRange)selection;
- (NSArray *)completionsWithSelection:(NSRange)selection;
- (NSArray *)diagnostics;
- (NSArray *)tokensForRange:(NSRange)range;
- (NSArray *)tokens;

@end
