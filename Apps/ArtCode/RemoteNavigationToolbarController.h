//
//  RemoteNavigationToolbarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/10/12.
//
//

#import <UIKit/UIKit.h>

@interface RemoteNavigationToolbarController : UIViewController

#pragma mark Local browser outlets
@property (weak, nonatomic) IBOutlet UIButton *localBackButton;
@property (weak, nonatomic) IBOutlet UILabel *localTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

#pragma mark Remote browser outlets
@property (weak, nonatomic) IBOutlet UIButton *remoteBackButton;
@property (weak, nonatomic) IBOutlet UILabel *remoteTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *remoteDeleteButton;

#pragma mark Actions
- (IBAction)taggedButtonAction:(id)sender;

/// Sends a next with the sender \c UIButton when it's pressed.
/// Buttons have tags: 0 - close button, 1 - local back button, 2 - upload, 3 - remote back button, 4 - download, 5 - remote delete
- (RACSubscribable *)buttonsActionSubscribable;

@end
