//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef CLANG_C_INDEX_H
//#define CLANG_C_INDEX_H // don't define it, so the compiler with throw errors if clang is included after this
typedef void *CXTranslationUnit;
typedef void *CXIndex;
#endif

extern NSString *ECClangTranslationUnitOptionLanguage;

@interface ECClangTranslationUnit : NSObject
@property (nonatomic, readonly) CXTranslationUnit translationUnit;
@property (nonatomic, readonly) CXFile source;
@property (nonatomic, readonly, retain) NSURL *fileURL;
- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options;
+ (id)translationUnitWithFile:(NSURL *)fileURL index:(CXIndex)index options:(NSDictionary *)options;
- (NSArray *)completionsWithSelection:(NSRange)selection;
- (NSArray *)diagnostics;
- (NSArray *)fixIts;
- (NSArray *)tokensInRange:(NSRange)range;
- (NSArray *)tokens;
@end
