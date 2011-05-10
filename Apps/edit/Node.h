//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDNode.h"
@class File;

@interface Node : CDNode
- (Node *)addNodeWithName:(NSString *)name type:(NSString *)type;
- (File *)addFileWithPath:(NSString *)path;
@end
