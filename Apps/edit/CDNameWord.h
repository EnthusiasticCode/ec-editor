//
//  CDNameWord.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDNode;

@interface CDNameWord : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * normalizedWord;
@property (nonatomic, retain) NSSet *nodes;
@end

@interface CDNameWord (CoreDataGeneratedAccessors)
- (void)addNodesObject:(CDNode *)value;
- (void)removeNodesObject:(CDNode *)value;
- (void)addNodes:(NSSet *)value;
- (void)removeNodes:(NSSet *)value;

@end
