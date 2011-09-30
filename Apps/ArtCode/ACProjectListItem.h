//
//  ProjectListItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACApplication, ACProject;

@interface ACProjectListItem : NSManagedObject

@property (nonatomic) int16_t tag;
@property (nonatomic, strong) NSURL *projectURL;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) ACApplication *application;

- (void)loadProjectWithCompletionHandler:(void(^)(ACProject *project))completionHandler;

@end
