//
//  CDNode.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDNameWord, CDNode;

@interface CDNode : NSManagedObject {
@private
}
@property (nonatomic) BOOL collapsed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int32_t tag;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSOrderedSet *children;
@property (nonatomic, retain) NSSet *nameWords;
@property (nonatomic, retain) CDNode *parent;
@end

@interface CDNode (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(CDNode *)value;
- (void)removeChildrenObject:(CDNode *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;
- (void)addNameWordsObject:(CDNameWord *)value;
- (void)removeNameWordsObject:(CDNameWord *)value;
- (void)addNameWords:(NSSet *)value;
- (void)removeNameWords:(NSSet *)value;

@end
