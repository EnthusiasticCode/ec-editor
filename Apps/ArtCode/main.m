//
//  main.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ArtCodeAppDelegate.h"

int main(int argc, char *argv[])
{
  int retVal = 0;
  @autoreleasepool {
    retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass(ArtCodeAppDelegate.class));
  }
  return retVal;
}
