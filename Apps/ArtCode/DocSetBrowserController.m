//
//  DocSetBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetBrowserController.h"
#import "ArtCodeTab.h"
#import "DocSetOutlineController.h"
#import "ShapePopoverBackgroundView.h"

@interface DocSetBrowserController () <UIWebViewDelegate>

/// The web view to show the docset content
@property (nonatomic, strong) UIWebView *webView;

/// Opens the popover with the docset contents controller
- (void)_toolNormalContentsAction:(id)sender;

@end

@implementation DocSetBrowserController {
  UIPopoverController *_outlinePopoverController;
}

#pragma mark - Properties

@synthesize docSetURL = _docSetURL;
@synthesize webView = _webView;

- (UIBarButtonItem *)editButtonItem {
  // To not show the edit button
  return nil;
}

#pragma mark - Controller's lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  // Add tool buttons
  self.toolbarItems = [NSArray arrayWithObjects:[UIBarButtonItem.alloc initWithTitle:@"O" style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalContentsAction:)], nil];
  
  // Update on docset changes
  [RACAbleSelf(self.artCodeTab.currentDocSet) subscribeNext:^(DocSet *docSet) {
    if (docSet != nil) {
      
    } else {
      // TODO show no docset selected
    }
  }];
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

#pragma mark - View lifecycle

- (void)loadView {
  [super loadView];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.delegate = self;
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.webView];
}

- (void)viewDidUnload {
  self.webView = nil;
  [super viewDidUnload];
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  return YES;
}

#pragma mark - Private Methods

- (void)_toolNormalContentsAction:(id)sender {
  if (!_outlinePopoverController) {
    DocSetOutlineController *outlineController = [DocSetOutlineController.alloc initWithDocSet:self.artCodeTab.currentDocSet rootNode:nil];
    UINavigationController *navigationController = [UINavigationController.alloc initWithRootViewController:outlineController];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    _outlinePopoverController = [UIPopoverController.alloc initWithContentViewController:navigationController];
    _outlinePopoverController.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
  }
  [_outlinePopoverController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

@end
