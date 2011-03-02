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
#import <ECCodeIndexing/ECCodeIndex.h>

@implementation editAppDelegate


@synthesize window = _window;
@synthesize codeView = _codeView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ECCodeProjectController *rootController;
    [[UINib nibWithNibName:@"CodeProjectController" bundle:nil] instantiateWithOwner:self.window options:nil];
    rootController = (ECCodeProjectController *) self.window.rootViewController;
    // directory must exist
    [rootController loadProjectFromRootDirectory:[NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit/"]]];
    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    NSDictionary *commentStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor greenColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    ECCodeView *codeView = (ECCodeView *) rootController.codeView;
    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
    [codeView setAttributes:commentStyle forStyleNamed:ECCodeStyleCommentName];
    
    // NOTE: codeview crashes if it is drawn without text
    codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
    
    [self.window addSubview:rootController.view];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
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
