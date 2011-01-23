//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

@implementation editAppDelegate


@synthesize window;
@synthesize codeView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    CTFontRef font = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
//    NSDictionary *attributes = [NSDictionary dictionaryWithObject:(id)font forKey:(id)kCTFontAttributeName];
//
//    codeView.attributedText = [[NSAttributedString alloc] initWithString:@"int main(arguments)\n{\n\treturn 0;\n}\n" attributes:attributes];
//
//    CFRelease(font);
    
    [window addSubview:codeView];
    
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
    [window release];
    [codeView release];
    [super dealloc];
}

@end
