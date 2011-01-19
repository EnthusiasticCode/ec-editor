//
//  ECCarpetViewController.h
//  edit
//
//  Created by Nicola Peduzzi on 18/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCarpetViewControllerDelegate.h"

@interface ECCarpetViewController : UIViewController {
}

// See ECCarpetViewControllerDelegate.h to informations on which methods this 
// dalagate may respond to.
@property (nonatomic, assign) id <ECCarpetViewControllerDelegate> delegate;

// Array of controllers managed by the carpet view controller. This array should
// be initialized before the first access to the view property.
// View controllers before mainControllerIndex will be positioned before the main
// view controller, the others will be positioned after.
@property (nonatomic, copy) NSArray *viewControllers;
 
// This view controller will be automatically sized to cover all the free space
// in the carpet. It must be contained in the viewControllers array.
@property (nonatomic, assign) UIViewController *mainViewController;

// Indicate the direction of the carpet. With horizontal direction, view cotnrollers
// will be displayed from left to right in every device orientation; With vertical
// direction from top to bottom.
@property (nonatomic) ECCarpetViewControllerDirection direction;

- (void)moveCarpetInDirection:(ECCarpetViewControllerMove)aSide animated:(BOOL)doAnimation;
- (IBAction)moveCarpetDownRight:(id)sender;
- (IBAction)moveCarpetUpLeft:(id)sender;

@end
