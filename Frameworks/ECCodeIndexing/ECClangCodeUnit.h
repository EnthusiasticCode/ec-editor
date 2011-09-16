//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECCodeUnitPlugin.h"
#import <clang-c/Index.h>

extern NSString *const ECClangCodeUnitOptionLanguage;
extern NSString *const ECClangCodeUnitOptionCXIndex;

@interface ECClangCodeUnit : NSObject <ECCodeUnitPlugin>
- (id)initWithFile:(NSString *)file index:(CXIndex)index language:(NSString *)language;
+ (id)unitForFile:(NSString *)file index:(CXIndex)index language:(NSString *)language;
@end
