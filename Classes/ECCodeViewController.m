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
      
    codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
    
    // Styles test
    ECTextStyle *stringStyle = [ECTextStyle textStyleWithName:@"String" 
                                                         font:[UIFont fontWithName:@"Courier New" size:16.0]
                                                        color:[UIColor orangeColor]];
    ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" 
                                                          font:[UIFont fontWithName:@"Courier New" size:16.0]
                                                         color:[UIColor blueColor]];
    [codeView setTextStyle:stringStyle toTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 9}]];
    [codeView setTextStyles:[NSArray arrayWithObjects:
                             keywordStyle, 
                             keywordStyle, nil] 
               toTextRanges:[NSArray arrayWithObjects:
                             [ECTextRange textRangeWithRange:(NSRange){0, 3}],
                             [ECTextRange textRangeWithRange:(NSRange){23, 6}], nil]];

    // Overlay test
    ECTextOverlayStyle *yellowMark = [ECTextOverlayStyle highlightTextOverlayStyleWithName:@"Yellow mark" 
                                                                                     color:[[UIColor yellowColor] colorWithAlphaComponent:0.5] 
                                                                          alternativeColor:nil 
                                                                              cornerRadius:1];
    ECTextOverlayStyle *errorMark = [ECTextOverlayStyle underlineTextOverlayStyleWithName:@"Error mark" 
                                                                                    color:[UIColor redColor] 
                                                                         alternativeColor:nil 
                                                                               waveRadius:1];
    [codeView addTextOverlayStyle:yellowMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    [codeView addTextOverlayStyle:errorMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];

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
