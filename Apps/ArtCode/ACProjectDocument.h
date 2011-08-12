//
//  ACProjectDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNode.h"

@interface ACProjectDocument : UIManagedDocument

@property (nonatomic, strong, readonly) ACNode *rootNode;

@end
