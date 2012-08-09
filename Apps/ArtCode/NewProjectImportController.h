//
//  NewProjectImportController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArtCodeProject;

@interface NewProjectImportController : UITableViewController

- (void)createProjectFromZipAtURL:(NSURL *)zipURL completionHandler:(void(^)(ArtCodeProject *project))block;

@end
