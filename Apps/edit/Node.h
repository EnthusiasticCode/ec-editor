//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
@class File, NameWord;

typedef enum
{
    NodeTypeFile = 0,
    NodeTypeFolder = 1,
    NodeTypeGroup = 2,
} NodeType;

@interface Node : NSManagedObject
@property (nonatomic) BOOL collapsed;
@property (nonatomic, strong) NSString * name;
@property (nonatomic) int32_t tag;
@property (nonatomic) int16_t type;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSOrderedSet *children;
@property (nonatomic, strong) NSSet *nameWords;
@property (nonatomic, strong) Node *parent;
- (Node *)addNodeWithName:(NSString *)name type:(NodeType)type;
@end

@interface Node (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(Node *)value;
- (void)removeChildrenObject:(Node *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;
- (void)addNameWordsObject:(NameWord *)value;
- (void)removeNameWordsObject:(NameWord *)value;
- (void)addNameWords:(NSSet *)value;
- (void)removeNameWords:(NSSet *)value;
@end
