//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../ECCodeUnitPlugin.h"

extern NSString *ECClangCodeUnitOptionLanguage;
extern NSString *ECClangCodeUnitOptionCXIndex;

@interface ECClangCodeUnit : NSObject <ECCodeUnitPlugin>
- (id)initWithFile:(NSURL *)fileURL index:(CXIndex)index language:(NSString *)language;
+ (id)unitWithFile:(NSURL *)fileURL index:(CXIndex)index language:(NSString *)language;
@end
