//
//  ACFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACNode.h"

@class ECCodeUnit;

@interface ACFile : ACNode

@property (nonatomic, strong, readonly) ECCodeUnit *codeUnit;

- (NSString *)contentString;

- (void)loadCodeUnitWithCompletionHandler:(void (^)(BOOL success))completionHandler;


@end
