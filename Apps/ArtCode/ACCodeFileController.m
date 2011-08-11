//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileController.h"
#import "ECCodeView.h"

@implementation ACCodeFileController

@synthesize codeView;

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
    NSString *urlContent = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
   codeView.text = urlContent;
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
    codeView = [ECCodeView new];
    codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = codeView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
