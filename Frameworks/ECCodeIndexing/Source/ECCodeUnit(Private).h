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
- (id)initWithIndex:(ECCodeIndex *)index url:(NSURL *)url language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin;
+ (id)unitWithIndex:(ECCodeIndex *)index url:(NSURL *)url language:(NSString *)language plugin:(id<ECCodeUnitPlugin>)plugin;
- (NSArray *)observedFiles;
- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)file;
- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)file;
@end
