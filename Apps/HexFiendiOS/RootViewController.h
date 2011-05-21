//
//  RootViewController.h
//  HexFiendiOS
//
//  Created by Uri Baghin on 5/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface RootViewController : UITableViewController {

}
		
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;
@property (nonatomic, retain) NSFileManager *fileManager;

- (NSString *)applicationDocumentsDirectory;
- (NSArray *)filesInDocumentsDirectory;

@end
