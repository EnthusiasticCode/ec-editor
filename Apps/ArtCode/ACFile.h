//
//  ACFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACPhysicalNode.h"

@class ECCodeUnit;

@interface ACFile : ACPhysicalNode

@property (nonatomic, strong, readonly) ECCodeUnit *codeUnit;

- (NSString *)contentString;

- (void)loadCodeUnitWithCompletionHandler:(void (^)(BOOL success))completionHandler;


@end
