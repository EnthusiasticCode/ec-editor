//
//  RenameController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/08/12.
//
//

#import <UIKit/UIKit.h>
@class RCIOItem;

/// A controller to manage a controller to rename a file.
@interface RenameController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithRenameItem:(RCIOItem *)item completionHandler:(void(^)(NSUInteger renamedCount, NSError *err))completionHandler;

#pragma mark Outlets

@property (weak, nonatomic) IBOutlet UITextField *renameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *renameFileIcon;
@property (weak, nonatomic) IBOutlet UIView *alsoRenameView;
@property (weak, nonatomic) IBOutlet UITableView *alsoRenameTableView;

@end
