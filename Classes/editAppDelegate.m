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
    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:
                                  (id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, 
                                  nil];
    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
    
    codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
    
    [codeView setStyleNamed:ECCodeStyleKeywordName toRange:(NSRange){0, 3}];
    
    // Overlay test
    NSDictionary *overlayAttrib = [NSDictionary dictionaryWithObject:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.5] forKey:ECCodeOverlayColorName];
    [codeView setAttributes:overlayAttrib forOverlayNamed:@"MyOverlay"];
    [codeView addOverlayNamed:@"MyOverlay" toRange:(NSRange){4, 4}];
    
    //
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
