//
//  ECClangCodeIndexer.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ECCodeIndexer.h"
#ifndef CLANG_C_INDEX_H
typedef void *CXIndex;
#endif
@class UITextChecker;

/*! Clang code indexer. Provides completion and syntax checking through Clang. */
@interface ECClangCodeIndexer : ECCodeIndexer{

}
@property (nonatomic, readonly) CXIndex cIndex;
@property (nonatomic, retain) UITextChecker *textChecker;

@end
