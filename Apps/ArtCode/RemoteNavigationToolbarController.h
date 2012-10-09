//
//  RemoteNavigationToolbarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 09/10/12.
//
//

#import <UIKit/UIKit.h>

@interface RemoteNavigationToolbarController : UIViewController

#pragma mark Editable outlets
@property (weak, nonatomic) IBOutlet UILabel *localTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *remoteTitleLabel;

#pragma mark Actions
- (IBAction)taggedButtonAction:(id)sender;

/// Sends a next with the sender \c UIButton when it's pressed.
/// Buttons have tags: 0 - close button, 1 - local back button, 2 - upload, 3 - remote back button, 4 - download
- (RACSubscribable *)buttonsActionSubscribable;

@end
