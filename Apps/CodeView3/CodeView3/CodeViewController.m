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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    codeView.contentMode = UIViewContentModeRedraw;
    codeView.text = @"int main(params)\n{ somethinghere\n\treturn 0;\n}";
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
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:[dir path]];
    NSInteger tag = [sender tag];
    NSString *s;
    for (NSURL *url in enumerator) {
        s = [url lastPathComponent];
        if (![s isEqualToString:@".DS_Store"] && tag-- <= 0) {
            NSStringEncoding enc;
            url = [dir URLByAppendingPathComponent:[url lastPathComponent]];
            s = [NSString stringWithContentsOfURL:url usedEncoding:&enc error:NULL];
            codeView.text = s;
            [sender setTitle:[url lastPathComponent]];
            break;
        }
    }
}

@end
