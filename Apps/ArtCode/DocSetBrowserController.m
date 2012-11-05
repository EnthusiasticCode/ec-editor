//
//  DocSetBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetBrowserController.h"
#import "UIViewController+Utilities.h"
#import "SingleTabController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

#import "DocSetContentController.h"
#import "DocSetOutlineController.h"
#import "DocSetBookmarksController.h"
#import "ImagePopoverBackgroundView.h"
#import "BezelAlert.h"

#import "DocSet.h"
#import "DocSetDownloadManager.h"

@interface DocSetBrowserController () <UIWebViewDelegate, DocSetBookmarksControllerDelegate>

/// The web view to show the docset content
@property (nonatomic, strong) UIWebView *webView;

/// Hints view that is placed over the webview when no docs is visible
@property (nonatomic, strong) UIView *hintsView;

/// Opens the popover with the docset contents controller
- (void)_toolNormalContentsAction:(id)sender;
- (void)_toolNormalBookmarksAction:(id)sender;

@end

@implementation DocSetBrowserController {
  UIPopoverController *_contentPopoverController;
  UIPopoverController *_outlinePopoverController;
  UIPopoverController *_bookmarkPopoverController;
}

#pragma mark - Properties

@synthesize webView = _webView, hintsView = _hintsView;

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
  self.toolbarItems = [NSArray arrayWithObjects:[UIBarButtonItem.alloc initWithImage:[UIImage imageNamed:@"itemIcon_Bookmarks"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalBookmarksAction:)], [UIBarButtonItem.alloc initWithImage:[UIImage imageNamed:@"itemIcon_Find"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalContentsAction:)], nil];
  
  // RAC
  __weak DocSetBrowserController *this = self;
  
  // Update on docset changes
  [[[[self rac_whenAny:[NSArray arrayWithObjects:@keypath(self.artCodeTab.currentLocation), @keypath(self.view.superview), nil] reduce:^id(RACTuple *xs) {
    return xs.first;
  }] where:^BOOL(id x) {
    return this.artCodeTab.currentLocation.url.docSet != nil && this.isViewLoaded;
  }] distinctUntilChanged] subscribeNext:^(NSURL *url) {
    DocSetBrowserController *strongSelf = this;
    if (url.path.length == 0) {
      // Show the hint view
      strongSelf.hintsView.frame = strongSelf.webView.frame;
      [strongSelf.view insertSubview:strongSelf.hintsView aboveSubview:strongSelf.webView];
      strongSelf.title = strongSelf.artCodeTab.currentLocation.url.docSet.name;
    } else {
      // Load the docset page
      [strongSelf.webView loadRequest:[NSURLRequest requestWithURL:url]];
      [strongSelf.hintsView removeFromSuperview];
    }
  }];
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_contentPopoverController dismissPopoverAnimated:NO];
  [_outlinePopoverController dismissPopoverAnimated:NO];
  [_bookmarkPopoverController dismissPopoverAnimated:NO];
}

#pragma mark - View lifecycle

- (void)loadView {
  [super loadView];
  
  self.hintsView = [[[NSBundle mainBundle] loadNibNamed:@"DocSetHintsView" owner:self options:nil] objectAtIndex:0];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.delegate = self;
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:self.webView];
}

- (void)viewDidUnload {
  self.webView = nil;
  self.hintsView = nil;
  _contentPopoverController = nil;
  _outlinePopoverController = nil;
  _bookmarkPopoverController = nil;
  [super viewDidUnload];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar {
  return self.hintsView.superview == nil;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender {
  if (!_outlinePopoverController) {
    DocSetOutlineController *outlineController = [[DocSetOutlineController alloc] init];
    
    UINavigationController *navigationController = [UINavigationController.alloc initWithRootViewController:outlineController];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    
    _outlinePopoverController = [UIPopoverController.alloc initWithContentViewController:navigationController];
    _outlinePopoverController.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
    
    outlineController.presentingPopoverController = _outlinePopoverController;
  }
  _outlinePopoverController.contentViewController.artCodeTab = self.artCodeTab;
  [_outlinePopoverController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}
#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  // This handler is quite complicated to manage artcode tab history and resolving redirects:
  // file:// are passed to the webview it they are a cached version of the actual docset page
  //         otherwise the request is ignored and pushed as a new docset URL to the history.
  // docset:// are converted into docset-file requests so that this handler can cache the page
  // docset-file:// are transformed into cached file and requested to the webview
	NSURL *URL = [request URL];
  
  // Redirect to docset link to enable history
  if ([URL.scheme isEqualToString:@"file"]) {
    
    // Cached files are the only request type allowed to pass
    if ([URL.path rangeOfString:@"__cached__"].location != NSNotFound) {
      return YES;
    }    
    
    // Otherwise redirect to a docset URL to enable history
    [self.artCodeTab pushDocSetURL:URL.docSetURLByRetractingFileURL];
    return NO;
  }
  
  // Resolve docset link and walk 
  if ([URL.scheme isEqualToString:@"docset"]) {
    URL = URL.docSetFileURLByResolvingDocSet;
    if (URL) {
      [webView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
    return NO;
  }
  
  // Docset files can be accessed directly from the webview in their cached version
	if ([URL.scheme isEqualToString:@"docset-file"]) {
//    NSInteger fragmentLocation = [URL.absoluteString rangeOfString:@"#"].location;
//    NSString *fragment = (fragmentLocation != NSNotFound) ? [URL.absoluteString substringFromIndex:fragmentLocation] : nil;
    
    NSURL *fileURL = [NSURL fileURLWithPath:URL.path];
    
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
        html = nil;
      }
    }
    
    // Calculate cacheing path
    NSString *cachePath = [[fileURL.path stringByDeletingPathExtension] stringByAppendingString:@"__cached__.html"];
    NSURL *cacheURL = [NSURL fileURLWithPath:cachePath];
    if (URL.fragment.length) {
      cacheURL = [NSURL URLWithString:[cacheURL.absoluteString stringByAppendingFormat:@"#%@", URL.fragment]];
    }
    
    // If the cached version already exists, send proper request
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
      [webView loadRequest:[NSURLRequest requestWithURL:cacheURL]];
      return NO;
    }
    
    // Cacheing
    static NSString *customCSS = @"<style>body { font-size: 16px !important; } pre { white-space: pre-wrap !important; }</style>";
    if (html == nil) {
      html = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
    }
    
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
      [html writeToURL:cacheURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
      [webView loadRequest:[NSURLRequest requestWithURL:cacheURL]];
      return NO;
    }
    
		return YES;
	}
  
  // Redirect to safari
  // TODO: complete with alert view delegate
  if ([URL.scheme hasPrefix:@"http"]) { //http or https
		[[[UIAlertView alloc] initWithTitle:L(@"Open Safari")
                                message:L(@"This is an external link. Do you want to open it in Safari?") 
                               delegate:self 
                      cancelButtonTitle:L(@"Cancel") 
                      otherButtonTitles:L(@"Open Safari"), nil] show];
		return NO;
	}
  
  ASSERT(NO); // Never reached
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  self.loading = NO;
  self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error {
  self.loading = NO;
	if ([error code] != -999) {
		//-999 is the code for "operation could not be completed", which would occur when a new page is requested before the current one has finished loading
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Error loading the page" imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
	}
}

#pragma mark - Bookmarks Controller Delegate

- (NSString *)docSetBookmarksController:(DocSetBookmarksController *)controller titleForBookmarksAtURL:(NSURL *)url anchorTitle:(NSString *__autoreleasing *)anchorTitle {
  // Subtitle
  if (anchorTitle) {
    NSString *fragment = url.fragment;
    if (fragment.length) {
      *anchorTitle = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var elements = document.getElementsByName('%@'); if (elements.length > 0) { elements[0].title; } else { ''; }", fragment]];
    }
  }
  // Title
  return [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - Private Methods

- (void)_toolNormalContentsAction:(id)sender {
  if (!_contentPopoverController) {
    DocSetContentController *contentController = [DocSetContentController.alloc initWithDocSet:self.artCodeTab.currentLocation.url.docSet rootNode:nil];
    UINavigationController *navigationController = [UINavigationController.alloc initWithRootViewController:contentController];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    _contentPopoverController = [UIPopoverController.alloc initWithContentViewController:navigationController];
    _contentPopoverController.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
    navigationController.presentingPopoverController = _contentPopoverController;
  }
  _contentPopoverController.contentViewController.artCodeTab = self.artCodeTab;
  [_contentPopoverController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolNormalBookmarksAction:(id)sender {
  if (!_bookmarkPopoverController) {
    DocSetBookmarksController *bookmarkController = [[DocSetBookmarksController alloc] init];
    bookmarkController.delegate = self;
    UINavigationController *navigationController = [UINavigationController.alloc initWithRootViewController:bookmarkController];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    _bookmarkPopoverController = [UIPopoverController.alloc initWithContentViewController:navigationController];
    _bookmarkPopoverController.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
    navigationController.presentingPopoverController = _bookmarkPopoverController;
  }
  _bookmarkPopoverController.contentViewController.artCodeTab = self.artCodeTab;
  [_bookmarkPopoverController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];  
}

@end
