//
//  DocSetBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetBrowserController.h"
#import "SingleTabController.h"
#import "ArtCodeTab.h"

#import "DocSetOutlineController.h"
#import "ShapePopoverBackgroundView.h"
#import "BezelAlert.h"

#import "DocSet.h"
#import "DocSetDownloadManager.h"

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
  [[RACAbleSelf(self.artCodeTab.currentURL) where:^BOOL(id x) {
    return self.artCodeTab.currentDocSet != nil;
  }] subscribeNext:^(NSURL *url) {
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
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
	NSURL *URL = [request URL];
  if ([URL.scheme isEqualToString:@"docset"]) {
    NSURL *fileURL = URL.fileURLByResolvingDocSet;
    if (!fileURL)
      return NO;
    
    // Handle soft redirects (they otherwise break the history):	
    NSString *html = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
    if (html) {
      static NSRegularExpression *metaRefreshRegex = nil;
      if (!metaRefreshRegex) {
        metaRefreshRegex = [NSRegularExpression regularExpressionWithPattern:@"<meta id=\"refresh\".*?URL=(.*?)\"" options:0 error:NULL];
      }
      NSTextCheckingResult *result = [metaRefreshRegex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
      if (result.numberOfRanges > 1) {
        NSString *relativeRedirectPath = [html substringWithRange:[result rangeAtIndex:1]];
        fileURL = [NSURL URLWithString:relativeRedirectPath relativeToURL:fileURL];
      }
    }
    
    // Open URL with webview
    [self.webView loadRequest:[NSURLRequest requestWithURL:fileURL]];
    return NO;
  }
  
	if ([[URL scheme] isEqualToString:@"file"]) {
		if ([[URL path] rangeOfString:@"__cached__"].location == NSNotFound) {
      static NSString *customCSS = @"<style>body { font-size: 16px !important; } pre { white-space: pre-wrap !important; }</style>";
      NSString *html = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL];
      
			//Rewrite HTML to get rid of the JavaScript that redirects to the "touch-friendly" page:
			NSScanner *scanner = [NSScanner scannerWithString:html];
			NSRange scriptRange;
			if ([scanner scanUpToString:@"<script>String.prototype.cleanUpURL" intoString:NULL]) {
				scriptRange.location = [scanner scanLocation];
				[scanner scanString:@"<script>String.prototype.cleanUpURL" intoString:NULL];
				[scanner scanUpToString:@"</script>" intoString:NULL];
				[scanner scanString:@"</script>" intoString:NULL];
				scriptRange.length = [scanner scanLocation] - scriptRange.location;
			} else {
				scriptRange = NSMakeRange(0, 0);
			}
			if (scriptRange.length > 0) {
				html = [html stringByReplacingCharactersInRange:scriptRange withString:customCSS];
				//We need to write the modified html to a file for back/forward to work properly.
				NSInteger anchorLocation = [[URL absoluteString] rangeOfString:@"#"].location;
				NSString *URLAnchor = (anchorLocation != NSNotFound) ? [[URL absoluteString] substringFromIndex:anchorLocation] : nil;
				NSString *path = [URL path];
				NSString *cachePath = [[path stringByDeletingPathExtension] stringByAppendingString:@"__cached__.html"];
				NSURL *cacheURL = [NSURL fileURLWithPath:cachePath];
				if (URLAnchor) {
					NSString *cacheURLString = [[cacheURL absoluteString] stringByAppendingFormat:@"%@", URLAnchor];
					cacheURL = [NSURL URLWithString:cacheURLString];
				}
				[html writeToURL:cacheURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
				[webView loadRequest:[NSURLRequest requestWithURL:cacheURL]];
				return NO;
			}
		}
		return YES;
	} else if ([[URL scheme] hasPrefix:@"http"]) { //http or https
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Open Safari", nil)
                                                    message:NSLocalizedString(@"This is an external link. Do you want to open it in Safari?", nil) 
                                                   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
                                          otherButtonTitles:NSLocalizedString(@"Open Safari", nil), nil];
		[alert show];
		return NO;
	}
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.loading = NO;
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
  self.loading = NO;
	if ([error code] != -999) {
		//-999 is the code for "operation could not be completed", which would occur when a new page is requested before the current one has finished loading
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Error loading the page" imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
	}
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
  _outlinePopoverController.contentViewController.artCodeTab = self.artCodeTab;
  [_outlinePopoverController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

@end
