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

    NSURL *fileURL = [NSURL URLWithString:@"../Documents/test.txt" relativeToURL:[[NSBundle mainBundle] bundleURL]];
    NSString *fileContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
    if (!fileContent) 
    {
        fileContent = @"int main(arguments)\n{\n\treturn 0;\n}";
    }

    codeView.text = fileContent;
//    [codeView sizeToFit];
    
//    // Styles test
//    ECTextStyle *stringStyle = [ECTextStyle textStyleWithName:@"String" 
//                                                         font:[UIFont fontWithName:@"Courier New" size:16.0]
//                                                        color:[UIColor orangeColor]];
//    ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" 
//                                                          font:[UIFont fontWithName:@"Courier New" size:16.0]
//                                                         color:[UIColor blueColor]];
//    [codeView setTextStyle:stringStyle toTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 9}]];
//    [codeView setTextStyles:[NSArray arrayWithObjects:
//                             keywordStyle, 
//                             keywordStyle, nil] 
//               toTextRanges:[NSArray arrayWithObjects:
//                             [ECTextRange textRangeWithRange:(NSRange){0, 3}],
//                             [ECTextRange textRangeWithRange:(NSRange){23, 6}], nil]];
//
//    // Overlay test
//    ECTextOverlayStyle *yellowMark = [ECTextOverlayStyle highlightTextOverlayStyleWithName:@"Yellow mark" 
//                                                                                     color:[[UIColor yellowColor] colorWithAlphaComponent:0.5] 
//                                                                              cornerRadius:1];
//    yellowMark.belowText = YES;
//    ECTextOverlayStyle *errorMark = [ECTextOverlayStyle underlineTextOverlayStyleWithName:@"Error mark" 
//                                                                                    color:[UIColor redColor] 
//                                                                               waveRadius:1];
//    [codeView addTextOverlayLayerWithStyle:yellowMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}]];
//    [codeView addTextOverlayLayerWithStyle:errorMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}]];
    
    // Edit tests
    
    // Focus recognizer
    focusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:codeView action:@selector(handleGestureFocus:)];
    [codeView addGestureRecognizer:focusRecognizer];

//    // Scroll view
//    [codeScrollView setMinimumZoomScale:1.0];
//    [codeScrollView setMaximumZoomScale:1.0];
//    codeScrollView.contentSize = CGSizeMake(100, 3000);
//    
//    codeScrollView.marks.lineCount = 100;
//    NSIndexSet *mlines = [NSIndexSet indexSetWithIndexesInRange:(NSRange){20,10}];
//    [codeScrollView.marks addMarksWithColor:[UIColor blueColor] forLines:mlines];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)dealloc 
{
    self.codeView = nil;
    [super dealloc];
}

- (IBAction)doSomething:(id)sender 
{
    codeView.text = @"Ciao!!";
}

@end
