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


@synthesize window = _window;
@synthesize codeView = _codeView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ECCodeIndexer loadLanguages];
    ECCodeProjectController *rootController;
    [[UINib nibWithNibName:@"CodeProjectController" bundle:nil] instantiateWithOwner:self.window options:nil];
    rootController = (ECCodeProjectController *) self.window.rootViewController;
    // directory must exist
    [rootController loadProject:@"edit" from:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit/"]];
    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    NSDictionary *commentStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor greenColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    ECCodeView *codeView = (ECCodeView *) rootController.codeView;
    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
    [codeView setAttributes:commentStyle forStyleNamed:ECCodeStyleCommentName];
    
    [self.window addSubview:rootController.view];
    [self.window makeKeyAndVisible];
    
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
