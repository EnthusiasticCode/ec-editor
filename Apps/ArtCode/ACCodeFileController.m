//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileController.h"
#import "ECCodeView.h"

#import "AppStyle.h"
#import "ACState.h"

@implementation ACCodeFileController

@synthesize codeView;

- (ECCodeView *)codeView
{
    if (!codeView)
    {
        codeView = [ECCodeView new];
        codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        codeView.backgroundColor = [UIColor whiteColor];
        codeView.caretColor = [UIColor styleThemeColorOne];
        codeView.selectionColor = [[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3];
    }
    return codeView;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool Target Protocol Implementation

+ (id)newNavigationTargetController
{
    return [ACCodeFileController new];
}

- (void)openURL:(NSURL *)url
{
    // TODO handle error
    id<ACStateNode> node = [[ACState localState] nodeForURL:url];
    ECASSERT([node respondsToSelector:@selector(fileURL)]);
    NSURL *fileURL = node.fileURL;
    NSString *urlContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    self.codeView.text = urlContent;
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return YES;
}

- (BOOL)shouldShowTabBar
{
    return YES;
}

- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController
{
    return YES;
}

- (void)applyFilter:(NSString *)filter
{
    // TODO
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self.codeView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
