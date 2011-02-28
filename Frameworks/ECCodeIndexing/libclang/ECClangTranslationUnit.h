//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Index.h"

@interface ECClangTranslationUnit : NSObject
@property (nonatomic) CXTranslationUnit translationUnit;
@property (nonatomic, retain) NSURL *file;
- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options;
+ (id)translationUnitWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options;
@end
