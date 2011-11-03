//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import "ACCodeFileController.h"
#import <ECFoundation/NSTimer+block.h>
#import <QuartzCore/QuartzCore.h>

#import <ECCodeIndexing/TMTheme.h>

#import <ECUIKit/ECTabController.h>
#import <ECUIKit/ECCodeView.h>

#import "ACCodeFileMinimapView.h"

#import "ACSingleTabController.h"
#import "ACCodeFileSearchBarController.h"



@interface ACCodeFileController () {
    UIActionSheet *_toolsActionSheet;
    ACCodeFileSearchBarController *_searchBarController;
}

@property (nonatomic, strong) ACFileDocument *document;

@end


@implementation ACCodeFileController

#pragma mark - Properties

@synthesize fileURL = _fileURL, tab = _tab, document = _document;
@synthesize codeView = _codeView, minimapView = _minimapView, minimapVisible = _minimapVisible;

- (void)setFileURL:(NSURL *)fileURL
{
    if (fileURL == _fileURL)
        return;
    
    [self willChangeValueForKey:@"fileURL"];
    
    _fileURL = fileURL;
    
    if (fileURL)
    {
        self.loading = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ACFileDocument *document = [[ACFileDocument alloc] initWithFileURL:fileURL];
            document.theme = [TMTheme themeWithName:@"Mac Classic" bundle:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.document = document;
                self.loading = NO;
            });
        });
    }
    
    [self didChangeValueForKey:@"fileURL"];
}

- (ACFileDocument *)document
{
    if (!self.fileURL)
        return nil;
    if (!_document)
    {
        self.document = [[ACFileDocument alloc] initWithFileURL:self.fileURL];
    }
    return _document;
}

- (void)setDocument:(ACFileDocument *)document
{
    if (document == _document)
        return;
    
    [self willChangeValueForKey:@"document"];
    
    [_document closeWithCompletionHandler:nil];
    _document = document;
    [_document openWithCompletionHandler:^(BOOL success) {
        ECASSERT(success);
        self.codeView.dataSource = _document;
    }];
    
    [self didChangeValueForKey:@"document"];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Toolbar Items Actions

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return YES;
}

- (void)toolButtonAction:(id)sender
{
    if (!_toolsActionSheet)
        _toolsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Show/hide tabs", @"Toggle find and replace", nil];
    
    [_toolsActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: // toggle tabs
        {
            [self.tabCollectionController setTabBarVisible:!self.tabCollectionController.isTabBarVisible animated:YES];
            break;
        }
            
        case 1: // toggle find/replace 
        {
            if (!_searchBarController)
            {
                _searchBarController = [[ACCodeFileSearchBarController alloc] initWithNibName:@"ACCodeFileSearchBarController" bundle:nil];
                _searchBarController.targetCodeFileController = self;
            }
            if (self.singleTabController.toolbarViewController != _searchBarController)
                [self.singleTabController setToolbarViewController:_searchBarController animated:YES];
            else
                [self.singleTabController setToolbarViewController:nil animated:YES];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    _codeView = [ECCodeView new];
        
    // Layout setup
    _codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _codeView.backgroundColor = [UIColor whiteColor];
    _codeView.caretColor = [UIColor blackColor]; // TODO use TMTheme cursor color
    _codeView.selectionColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
    _codeView.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    _codeView.lineNumbersEnabled = YES;
    _codeView.lineNumbersWidth = 30;
    _codeView.lineNumbersFont = [UIFont systemFontOfSize:10];
    _codeView.lineNumbersColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    _codeView.alwaysBounceVertical = YES;
    _codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:_codeView];
    
    _minimapView = [[ACCodeFileMinimapView alloc] initWithFrame:CGRectZero];
    _minimapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _minimapView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    _minimapView.rendererMinimumLineWidth = 4;
    _minimapView.renderer = _codeView.renderer;
    _minimapView.backgroundColor = [UIColor grayColor];
    _minimapView.lineShadowColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self.view addSubview:_minimapView];
}

- (void)viewDidLoad
{
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"tools" style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _toolsActionSheet = nil;
    _searchBarController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGRect frame = self.view.frame;
#warning TODO NIK actually use minimapVisible
    _codeView.frame = CGRectMake(0, 0, frame.size.width - 124, frame.size.height);
    _minimapView.frame = CGRectMake(frame.size.width - 124, 0, 124, frame.size.height);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Minimap Data Source Methods

- (NSUInteger)numberOfLinesForCodeFileMinimapView:(ACCodeFileMinimapView *)minimapView
{
    return [self.document lineCount];
}

- (CGFloat)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView lenghtOfLineAtIndex:(NSUInteger)lineIndex applyColor:(UIColor *__autoreleasing *)lineColor
{
//    self.codeView.renderer 
}

@end
