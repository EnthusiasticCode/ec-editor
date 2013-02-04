//
//  MoveConflictController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RCIODirectory, RCIOItem;


// A controller used to verify if some items can be safelly move to another destination. If conflicts are found, the controller shows a UI that permits to the user to resolve them. The main function is processItems:destinationFolder:usingBlock:completion: that starts the checking process.
@interface MoveConflictController : UIViewController <UITableViewDelegate, UITableViewDataSource>

// Process the array of RCIOItems by comparing their name with those of items in the given folder. For resolved items (both automatically and from user input) the provided block is applied. At the end of the processing, the completion block is called.
- (RACSignal *)moveItems:(NSArray *)items
                        toFolder:(RCIODirectory *)destinationFolder
          usingSignalBlock:(RACSignal *(^)(RCIOItem *item, RCIODirectory *destinationFolder))signalBlock;

#pragma mark Interface Actions and Outlets

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITableView *conflictTableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

- (IBAction)doneAction:(id)sender;
- (IBAction)selectAllAction:(id)sender;
- (IBAction)selectNoneAction:(id)sender;

@end
