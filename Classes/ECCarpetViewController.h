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

// The index in viewControllers of the main view controller. 
// This view controller will be automatically sized to cover all the free space
// in the carpet.
@property (nonatomic) NSInteger mainControllerIndex;

// Sizes for the corresponding viewController's view controller 
// in landscape (width) and portraint (height) orientation independent 
// by direction of the carpet.
// If the value is smaller than 1, it will be interpreted as a percentual
// of the parent view. To initialize this array consider using the following:
// [NSArray arrayWithObjects: [NSValue valueWithCGSize:CGSizeMake(0.3, 0.3), …, nil]];
// Value corresponding to mainControllerIndex will be ignored.
@property (nonatomic, copy) NSArray *viewControllersSizes;

// Indicate the direction of the carpet. With horizontal direction, view cotnrollers
// will be displayed from left to right in every device orientation; With vertical
// direction from top to bottom.
@property (nonatomic) ECCarpetViewControllerDirection direction;

- (void)moveCarpetInDirection:(ECCarpetViewControllerMove)aSide animated:(BOOL)doAnimation;
- (IBAction)moveCarpetDownRight:(id)sender;
- (IBAction)moveCarpetUpLeft:(id)sender;

@end
