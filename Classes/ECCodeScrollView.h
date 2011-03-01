//
//  ECCodeScrollView.h
//  edit
//
//  Created by Nicola Peduzzi on 01/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECLineMarksView.h"

@interface ECCodeScrollView : UIScrollView {
@private
    ECLineMarksView *marks;
}

@property (nonatomic, retain) ECLineMarksView *marks;

@end
