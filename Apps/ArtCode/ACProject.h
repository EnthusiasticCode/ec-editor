//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ACProjectFolder;

@interface ACProject : UIDocument

@property (nonatomic, strong, readonly) id UUID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id labelColor; // UIColor or NSString with hex color of the project’s label
@property (nonatomic, strong, readonly) ACProjectFolder *rootFolder;
@property (nonatomic, strong, readonly) NSArray *bookmarks;
@property (nonatomic, strong, readonly) NSArray *remotes;
- (void)exportToArchiveWithURL:(NSURL *)archiveURL completionHandler:(void(^)(BOOL success))completionHandler;
+ (NSURL *)projectsURL;
+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void(^)(BOOL success))completionHandler;

@end
