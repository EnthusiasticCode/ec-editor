//
//  ItemViewViewController.h
//  ItemView
//
//  Created by Uri Baghin on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECItemView.h"

@interface ItemViewViewController : UIViewController <ECItemViewDataSource, ECItemViewDelegate> {
    
    ECItemView *itemViewA;
    ECItemView *itemViewB;
}
@property (nonatomic, retain) IBOutlet ECItemView *itemViewA;
@property (nonatomic, retain) IBOutlet ECItemView *itemViewB;
- (IBAction)batchUpdates:(id)sender;

@end
