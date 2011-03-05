//
//  ECCodeViewController.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewController.h"


@implementation ECCodeViewController

@synthesize codeView;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    // TODO try without this initialization to find more bugs
//    
    codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
//    
//    // Styles test
//    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:
//                                  (id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, 
//                                  nil];
//    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
//    [codeView setStyleNamed:ECCodeStyleKeywordName toRange:(NSRange){0, 3}];
//    
//    // Overlay test
//    NSDictionary *overlayAttrib = [NSDictionary dictionaryWithObject:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.5] forKey:ECCodeOverlayAttributeColorName];
//    [codeView setAttributes:overlayAttrib forOverlayNamed:@"MyOverlay"];
//    [codeView addOverlayNamed:@"MyOverlay" toRange:(NSRange){4, 4}];
//    
//    // Scroll view
//    [codeScrollView setMinimumZoomScale:1.0];
//    [codeScrollView setMaximumZoomScale:1.0];
//    codeScrollView.contentSize = CGSizeMake(100, 3000);
//    
//    codeScrollView.marks.lineCount = 100;
//    NSIndexSet *mlines = [NSIndexSet indexSetWithIndexesInRange:(NSRange){20,10}];
//    [codeScrollView.marks addMarksWithColor:[UIColor blueColor] forLines:mlines];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc 
{
    self.codeView = nil;
    [super dealloc];
}


@end
