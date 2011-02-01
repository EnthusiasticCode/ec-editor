//
//  ECClangTranslationUnit.h
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef CLANG_C_INDEX_H
typedef void *CXIndex;
#endif

typedef enum ECClangLanguage
{
    ECClangLanguage_ObjectiveC = 1
} ECClangLanguage;

@interface ECClangTranslationUnit : NSObject {

}
@property (nonatomic, readonly, retain) NSArray *diagnostics;
- (id)initWithIndex:(CXIndex)index source:(NSString *)source language:(ECClangLanguage)language options:(NSDictionary *)options;
- (id)initWithIndex:(CXIndex)index source:(NSString *)source;

@end
