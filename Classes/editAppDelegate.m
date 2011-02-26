//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

#import "ECCodeProject.h"
#import "ECCodeProjectController.h"
#import <ECCodeIndexing/ECCodeIndexer.h>

@implementation editAppDelegate


@synthesize window;
@synthesize codeView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ECCodeIndexer loadLanguages];
    ECCodeProjectController *rootController;
    [[UINib nibWithNibName:@"CodeProjectController" bundle:nil] instantiateWithOwner:window options:nil];
    rootController = (ECCodeProjectController *) window.rootViewController;
    // directory must exist
    [rootController loadProject:@"edit" from:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit/"]];
    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:
                                  (id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, 
                                  nil];
    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
    
    codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
    
    [codeView setStyleNamed:ECCodeStyleKeywordName toRange:(NSRange){0, 3}];
    
    [window addSubview:rootController.view];
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
    [ECCodeIndexer unloadLanguages];
    self.window = nil;
		self.codeView = nil;
		[super dealloc];
}

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
