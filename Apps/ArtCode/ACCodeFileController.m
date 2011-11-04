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

#import "ACSingleTabController.h"
#import "ACCodeFileSearchBarController.h"



@interface ACCodeFileController () {
    UIActionSheet *_toolsActionSheet;
    ACCodeFileSearchBarController *_searchBarController;
}

@property (nonatomic, strong) ACFileDocument *document;

- (void)_layoutChildViews;

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer;
- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer;

@end


@implementation ACCodeFileController

#pragma mark - Properties

@synthesize fileURL = _fileURL, tab = _tab, document = _document;
@synthesize codeView = _codeView, minimapView = _minimapView, minimapVisible = _minimapVisible, minimapWidth = _minimapWidth;

- (ECCodeView *)codeView
{
    if (!_codeView)
    {
        _codeView = [ECCodeView new];
        _codeView.delegate = self;
        
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
        
        UISwipeGestureRecognizer *undoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureUndo:)];
        undoRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        undoRecognizer.numberOfTouchesRequired = 2;
        [_codeView addGestureRecognizer:undoRecognizer];
        
        UISwipeGestureRecognizer *redoRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleGestureRedo:)];
        redoRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        undoRecognizer.numberOfTouchesRequired = 2;
        [_codeView addGestureRecognizer:redoRecognizer];
    }
    return _codeView;
}

- (ACCodeFileMinimapView *)minimapView
{
    if (!_minimapView)
    {
        _minimapView = [ACCodeFileMinimapView new];
        _minimapView.delegate = self;
        _minimapView.renderer = self.codeView.renderer;
        
        _minimapView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        _minimapView.contentInset = UIEdgeInsetsMake(10, 0, 10, 10);
        _minimapView.alwaysBounceVertical = YES;
        
        _minimapView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"minimap_Background"]];
        _minimapView.backgroundView.contentMode = UIViewContentModeTopLeft;
        _minimapView.lineDecorationInset = 10;
        _minimapView.lineShadowColor = [UIColor colorWithWhite:0 alpha:0.75];
        _minimapView.lineDefaultColor = [UIColor colorWithWhite:0.7 alpha:1];
    }
    return _minimapView;
}

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

- (CGFloat)minimapWidth
{
    if (_minimapWidth == 0)
        _minimapWidth = 124;
    return _minimapWidth;
}

- (void)setMinimapVisible:(BOOL)minimapVisible
{
    [self setMinimapVisible:minimapVisible animated:NO];
}

- (void)setMinimapVisible:(BOOL)minimapVisible animated:(BOOL)animated
{
    if (_minimapVisible == minimapVisible)
        return;
    
    [self willChangeValueForKey:@"minimapVisible"];
    if (minimapVisible)
        [self.view addSubview:self.minimapView];
    if (animated)
    {
        [self _layoutChildViews];
        _minimapVisible = minimapVisible;
        [UIView animateWithDuration:0.25 animations:^{
            [self _layoutChildViews];
        } completion:^(BOOL finished) {
            if (!_minimapVisible)
                [_minimapView removeFromSuperview];
        }];
    }
    else
    {
        _minimapVisible = minimapVisible;
        if (!_minimapVisible)
            [_minimapView removeFromSuperview];
        [self _layoutChildViews];
    }
    [self didChangeValueForKey:@"minimapVisible"];
}

#pragma mark - Toolbar Items Actions

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return YES;
}

- (void)toolButtonAction:(id)sender
{
    if (!_toolsActionSheet)
        _toolsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select action" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Toggle find and replace", @"Toggle minimap", @"Show/hide tabs", nil];
    
    [_toolsActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {    
        case 0: // toggle find/replace 
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
        
        case 1: // toggle minimap
        {
            [self setMinimapVisible:!self.minimapVisible animated:YES];
            if (self.minimapVisible)
                self.minimapView.selectionRectangle = self.codeView.bounds;
            break;
        }
            
        case 2: // toggle tabs
        {
            [self.tabCollectionController setTabBarVisible:!self.tabCollectionController.isTabBarVisible animated:YES];
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
    
    [self.view addSubview:self.codeView];
}

- (void)viewDidLoad
{
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"tools" style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _minimapView = nil;
    _codeView = nil;
    
    _toolsActionSheet = nil;
    _searchBarController = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _layoutChildViews];
}

#pragma mark - Controller Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.minimapVisible)
        self.minimapView.selectionRectangle = self.codeView.bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if (!_minimapVisible)
        _minimapView = nil;
}

#pragma mark - Minimap Delegate Methods

- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldRenderLine:(ECTextRendererLine *)line number:(NSUInteger)lineNumber withColor:(UIColor *__autoreleasing *)lineColor deocration:(ACCodeFileMinimapLineDecoration *)decoration decorationColor:(UIColor *__autoreleasing *)decorationColor
{
    if (line.width < line.height)
        return NO;
    
    if (lineNumber < 8)
        *lineColor = [UIColor greenColor];
    
    if (lineNumber == 15)
    {
        *decoration = ACCodeFileMinimapLineDecorationDisc;
        *decorationColor = [UIColor whiteColor];
    }
    
    if (lineNumber == 154)
    {
        *decoration = ACCodeFileMinimapLineDecorationSquare;
        *decorationColor = [UIColor whiteColor];
    }
    
    return YES;
}

- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldChangeSelectionRectangle:(CGRect)newSelection
{
    [self.codeView scrollRectToVisible:newSelection animated:YES];
    return NO;
}

#pragma mark - Code View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_minimapVisible && scrollView == _codeView)
    {
        _minimapView.selectionRectangle = _codeView.bounds;
    }
}

#pragma mark - Private Methods

- (void)_layoutChildViews
{
    CGRect frame = (CGRect){ CGPointZero, self.view.frame.size };
    if (self.minimapVisible)
    {
        self.codeView.frame = CGRectMake(0, 0, frame.size.width - self.minimapWidth, frame.size.height);
        self.minimapView.frame = CGRectMake(frame.size.width - self.minimapWidth, 0, self.minimapWidth, frame.size.height);
    }
    else
    {
        self.codeView.frame = frame;
        _minimapView.frame = CGRectMake(frame.size.width, 0, self.minimapWidth, frame.size.height);
    }
}

- (void)_handleGestureUndo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager undo];
}

- (void)_handleGestureRedo:(UISwipeGestureRecognizer *)recognizer
{
    [_codeView.undoManager redo];
}

@end
