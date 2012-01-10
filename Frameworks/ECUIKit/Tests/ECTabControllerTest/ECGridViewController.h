//
//  ECGridViewController.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECGridView.h"

@interface ECGridViewController : UIViewController <ECGridViewDelegate, ECGridViewDataSource>

@end


@interface TestCell : ECGridViewCell
@property (nonatomic, readonly, strong) UILabel *label;
@end