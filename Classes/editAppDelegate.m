//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

#import "ECCodeViewController.h"
#import "ECCodeView.h"

@implementation editAppDelegate


@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CTFontRef font = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)font forKey:(id)kCTFontAttributeName];
    ((ECCodeView *)((ECCodeViewController *)window.rootViewController).view).attributedText = [[NSAttributedString alloc] initWithString:@"int main(arguments)\n{\n\treturn 0;\n}\n" attributes:attributes];
    
    [window addSubview:window.rootViewController.view];
    [window makeKeyAndVisible];
    
		CFRelease(font);
    return YES;
}

- (void)dealloc
{
    self.window = nil;
    [super dealloc];
}

@end
