//
//  ACPhysicalNode.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"

@class ACPhysicalNode;

@interface ACPhysicalNode : ACNode

@property (nonatomic, strong) NSOrderedSet *physicalChildren;
@property (nonatomic, strong) ACPhysicalNode *physicalParent;

@end
