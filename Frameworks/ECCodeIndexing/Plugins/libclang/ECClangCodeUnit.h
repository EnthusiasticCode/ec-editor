//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ECCodeIndexing/ECCodeUnitPlugin.h>

extern NSString *ECClangCodeUnitOptionLanguage;
extern NSString *ECClangCodeUnitOptionCXIndex;

@interface ECClangCodeUnit : NSObject <ECCodeUnitPlugin>
- (id)initWithFile:(NSString *)file index:(CXIndex)index language:(NSString *)language;
+ (id)unitForFile:(NSString *)file index:(CXIndex)index language:(NSString *)language;
@end
