//
//  DocSetBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetBrowserController.h"
#import "ArtCodeTab.h"

@interface DocSetBrowserController () <UIWebViewDelegate>

/// The web view to show the docset content
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation DocSetBrowserController

#pragma mark - Properties

@synthesize docSetURL = _docSetURL;
@synthesize webView = _webView;

#pragma mark - Controller's lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
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

@end
