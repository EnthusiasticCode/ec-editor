//
//  ACNode.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CDNode.h"

typedef enum
{
    ACNodeTypeFolder,
    ACNodeTypeGroup,
    ACNodeTypeSourceFile,
} ACNodeType;

@interface ACNode : CDNode

- (NSString *)absolutePath;
- (NSInteger)depth;
- (ACNode *)addNodeWithName:(NSString *)name type:(ACNodeType)type;

@end
