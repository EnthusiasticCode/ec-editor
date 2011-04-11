//
//  CodeViewController.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeViewController.h"


@implementation CodeViewController
@synthesize codeView;
@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [scrollView release];
    [codeView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    codeView.autosizeHeigthToFitTextOnBoundsChange = YES;
    codeView.contentMode = UIViewContentModeRedraw;
    [codeView setText:[[NSMutableAttributedString alloc] initWithString:@"int main(params)\n{\n\treturn 0;\n}"] applyDefaultAttributes:YES];
    [codeView setFrame:self.view.bounds autosizeHeightToFitText:YES];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)loadTestFileToCodeView:(id)sender 
{
    NSURL *dir = [NSURL URLWithString:@"../Documents" relativeToURL:[[NSBundle mainBundle] bundleURL]];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:dir includingPropertiesForKeys:nil options:0 errorHandler:nil];
    NSInteger tag = [sender tag];
    for (NSURL *url in enumerator) {
        if (tag-- > 0) {
            NSStringEncoding enc;
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:url usedEncoding:&enc error:NULL]];
            [codeView setText:string applyDefaultAttributes:YES];
            [string release];
            break;
        }
    }
}
@end
