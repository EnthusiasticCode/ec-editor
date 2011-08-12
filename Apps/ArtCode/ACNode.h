//
//  ACNode.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CDNode.h"
#import "ACState.h"

typedef enum
{
    ACNodeTypeFolder,
    ACNodeTypeGroup,
    ACNodeTypeSourceFile,
} ACNodeType;

@interface ACNode : CDNode <ACStateNode>

- (NSString *)absolutePath;
- (NSInteger)depth;
- (ACNode *)addNodeWithName:(NSString *)name type:(ACNodeType)type;
- (ACNode *)childNodeWithName:(NSString *)name;

@end
