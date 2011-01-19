//
//  ECCodeViewController.h
//  edit
//
//  Created by Uri Baghin on 1/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UITextChecker.h>
#import <UIKit/UIPopoverController.h>

#import "ECCodeView.h"
#import "ECPopoverTableController.h"

#import "libclang/Index.h"

@interface ECCodeViewController : UIViewController <ECPopoverTableControllerDelegate>
{

}

@property (nonatomic, retain) UITextChecker *textChecker;
@property (nonatomic, retain) ECPopoverTableController *completionPopover;

- (NSRange)completionRange;
- (void)showCompletions;

@end
