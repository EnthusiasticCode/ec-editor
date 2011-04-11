//
//  CodeView3AppDelegate.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView3.h"

@interface CodeView3AppDelegate : NSObject <UIApplicationDelegate> {


}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ECCodeView3 *codeView;

@end
