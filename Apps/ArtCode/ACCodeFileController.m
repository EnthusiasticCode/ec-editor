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

#import <QuartzCore/QuartzCore.h>

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
        codeView.textInsets = UIEdgeInsetsMake(10, 40, 10, 10);
        
        codeView.lineNumberWidth = 30;
        codeView.lineNumberFont = [UIFont systemFontOfSize:10];
        codeView.lineNumberColor = [UIColor colorWithWhite:0.8 alpha:1];
        // TODO maybe is not the best option to draw the line number in an external block
        codeView.lineNumberRenderingBlock = ^(CGContextRef context, CGRect lineNumberBounds, CGFloat baseline, NSUInteger lineNumber, BOOL isWrappedLine) {
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1].CGColor);
            CGContextMoveToPoint(context, lineNumberBounds.size.width + 3, 0);
            CGContextAddLineToPoint(context, lineNumberBounds.size.width + 3, lineNumberBounds.size.height);
            CGContextStrokePath(context);
            
//            if (!isWrappedLine)
//                return;
//
//            CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
//            CGContextFillRect(context, lineNumberBounds);
        };
        
        codeView.renderer.preferredLineCountPerSegment = 500;
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
    id<ACStateNode> node = [[ACState sharedState] nodeForURL:url];
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
