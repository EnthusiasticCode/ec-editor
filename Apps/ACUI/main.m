//
//  main.m
//  ACUI
//
//  Created by Nicola Peduzzi on 09/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ACUIAppDelegate.h"

int main(int argc, char *argv[])
{
    int retVal = 0;
    @autoreleasepool {
        retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([ACUIAppDelegate class]));
    }
    return retVal;
}
