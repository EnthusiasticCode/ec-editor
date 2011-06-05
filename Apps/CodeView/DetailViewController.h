//
//  DetailViewController.h
//  CodeView
//
//  Created by Nicola Peduzzi on 27/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"
#import "ECCodeByteArrayDataSource.h"

@interface DetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate, UIScrollViewDelegate> {

    ECCodeView *_codeView;
    ECCodeByteArrayDataSource *codeViewDataSource;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

@property (nonatomic, retain) id detailItem;

@property (nonatomic, retain) IBOutlet UILabel *detailDescriptionLabel;

@property (nonatomic, retain) IBOutlet ECCodeView *codeView;

- (IBAction)completeAtCursor:(id)sender;

@end
