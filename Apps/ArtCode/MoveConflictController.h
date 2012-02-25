//
//  MoveConflictController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoveConflictController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic, readonly) NSMutableArray *conflictURLs;

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UITableView *conflictTableView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

- (void)processItemURLs:(NSArray *)itemURLs toURL:(NSURL *)destinationURL usignProcessingBlock:(void (^)(NSURL *itemURL, NSURL *destinationURL))processingBlock completion:(void(^)(void))completionBlock;

- (IBAction)doneAction:(id)sender;

- (IBAction)selectAllAction:(id)sender;
- (IBAction)selectNoneAction:(id)sender;
- (IBAction)keepBothAction:(id)sender;
- (IBAction)keepOriginalAction:(id)sender;
- (IBAction)replaceAction:(id)sender;

@end
