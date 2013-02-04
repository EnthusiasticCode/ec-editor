//
//  RemoteFileListController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import <UIKit/UIKit.h>
#import "SearchableTableBrowserController.h"

@class ArtCodeRemote, ReactiveConnection;

@interface RemoteFileListController : SearchableTableBrowserController

// Make the controller use the given connection to connect to the remote path.
- (void)prepareWithConnection:(ReactiveConnection *)connection artCodeRemote:(ArtCodeRemote *)remote path:(NSString *)remotePath;

// Returns the full remote path that the controller is listing.
@property (nonatomic, readonly, strong) NSString *remotePath;

// An array of Connection items currently selected
@property (nonatomic, readonly, copy) NSArray *selectedItems;

// Adds an item to the list that will be presented as non-selectable files with download progress.
// The signal is expected to yield NSNumbers with percent progress, any other kind of value will be ignored.
// When the signal completes, the item will be removed.
- (void)addProgressItemWithURL:(NSURL *)url progressSignal:(RACSignal *)progressSignal;

// Refresh the content of the list from the server.
- (void)refresh;

#pragma mark Login panel outlets

@property (strong, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UITextField *loginUser;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;
@property (weak, nonatomic) IBOutlet UISwitch *loginAlwaysAskPassword;
@property (weak, nonatomic) IBOutlet UILabel *loginErrorMessage;
- (IBAction)loginAction:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *loadingView;

@end
