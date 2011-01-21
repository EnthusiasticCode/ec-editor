//
//  ECCodeProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeProject.h"
#import "ECCodeView.h"

@interface ECCodeProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate> {
    
}
@property (nonatomic, retain, readonly) ECCodeProject *project;
@property (nonatomic, retain, readonly) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet ECCodeView *codeView;

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory;
- (NSArray *)contentsOfRootDirectory;

@end
