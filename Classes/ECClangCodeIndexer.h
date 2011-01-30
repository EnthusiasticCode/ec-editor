//
//  ECClangCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UITextChecker.h>

#import "ECCodeIndexer.h"
#import "Index.h"

/*! Clang code indexer. Provides completion and syntax checking through Clang. */
@interface ECClangCodeIndexer : ECCodeIndexer <ECCodeIndexer> {

}
@property (nonatomic, readonly) CXIndex cIndex;
@property (nonatomic, retain) UITextChecker *textChecker;

- (NSRange)completionRangeWithSelection:(NSRange)selection inString:(NSString *)string;

@end
