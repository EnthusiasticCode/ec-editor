//
//  Header.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"

@interface ECCodeUnit (Private)
@property (nonatomic, retain) ECCodeIndex *index;
- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)file;
- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)file;
@end
