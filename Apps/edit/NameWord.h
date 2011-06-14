//
//  NameWord.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Node;

@interface NameWord : NSManagedObject
@property (nonatomic, strong) NSString * normalizedWord;
@property (nonatomic, strong) NSSet *nodes;
@end

@interface NameWord (CoreDataGeneratedAccessors)
- (void)addNodesObject:(Node *)value;
- (void)removeNodesObject:(Node *)value;
- (void)addNodes:(NSSet *)value;
- (void)removeNodes:(NSSet *)value;

@end
