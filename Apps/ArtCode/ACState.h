//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACState : NSObject

+ (ACState *)sharedState;
@property (nonatomic, copy, readonly) NSOrderedSet *projects;
- (NSString *)applicationDocumentsDirectory;
- (NSArray *)projectBundlesInApplicationDocumentsDirectory;
@property (nonatomic, strong, readonly) NSFileManager *fileManager;
- (void)scanForProjects;

@end
