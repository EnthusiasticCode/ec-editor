//
//  ECCarpetViewControllerDelegate.h
//  edit
//
//  Created by Nicola Peduzzi on 18/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCarpetViewController;

typedef enum {
    ECCarpetHorizontal = 0,
    ECCarpetVertical
} ECCarpetViewControllerDirection;

typedef enum {
    ECCarpetMoveUpOrLeft = 0,
    ECCarpetMoveDownOrRight
} ECCarpetViewControllerMove;

@protocol ECCarpetViewControllerDelegate <NSObject>

- (BOOL)carpetViewController:(ECCarpetViewController*)cvc 
                  willMoveTo:(ECCarpetViewControllerMove)aDirection
       showingViewController:(UIViewController*)aShowableViewController
        hidingViewController:(UIViewController*)aHidableViewController;

- (void)carpetViewController:(ECCarpetViewController*)cvc 
                   didMoveTo:(ECCarpetViewControllerMove)aDirection
       showingViewController:(UIViewController*)aShownViewController
        hidingViewController:(UIViewController*)aHidedViewController;

@end
