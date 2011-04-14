//
//  ItemViewAppDelegate.h
//  ItemView
//
//  Created by Uri Baghin on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ItemViewViewController;

@interface ItemViewAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet ItemViewViewController *viewController;

@end
