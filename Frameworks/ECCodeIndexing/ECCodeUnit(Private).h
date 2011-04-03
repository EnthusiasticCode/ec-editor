//
//  Header.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"
#import "ECCodeUnitPlugin.h"

@interface ECCodeUnit (Private)
- (id)initWithIndex:(ECCodeIndex *)index file:(NSString *)file language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin;
+ (id)unitWithIndex:(ECCodeIndex *)index file:(NSString *)file language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin;
- (NSArray *)observedFiles;
- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
@end
