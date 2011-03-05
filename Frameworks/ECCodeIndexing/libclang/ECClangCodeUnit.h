//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../ECCodeIndex.h"
#import "../ECCodeUnit.h"

extern NSString *ECClangCodeUnitOptionLanguage;
extern NSString *ECClangCodeUnitOptionCXIndex;

@interface ECClangCodeUnit : ECCodeUnit
- (id)initWithFile:(NSURL *)fileURL options:(NSDictionary *)options;
+ (id)unitWithFile:(NSURL *)fileURL options:(NSDictionary *)options;
@end
