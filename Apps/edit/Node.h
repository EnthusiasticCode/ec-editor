//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CDNode.h"
@class File;

typedef enum
{
    NodeTypeFile = 0,
    NodeTypeFolder = 1,
    NodeTypeGroup = 2,
} NodeType;

@interface Node : CDNode
- (Node *)addNodeWithName:(NSString *)name type:(NodeType)type;
- (File *)addFileWithPath:(NSString *)path;
@end
