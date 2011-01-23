//
//  ECCodeViewController.m
//  edit
//
//  Created by Uri Baghin on 1/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeViewController.h"

#import "ECCodeView.h"
#import "ECClangCodeIndexer.h"


@implementation ECCodeViewController


#pragma mark -
#pragma mark Initializations and clean up

- (void)viewDidLoad
{
    ECCodeView *codeView = (ECCodeView *)self.view;
    // viewDidLoad can be called multiple times without deallocating the view
    if (![codeView.completionProviders count])
    {
        ECClangCodeIndexer *codeIndexer = [[ECClangCodeIndexer alloc] init];
        [codeView addCompletionProvider:codeIndexer];
        [codeIndexer release];
        codeView.delegate = (id)self;
    }
}

- (void)dealloc
{
    self.view = nil;
    [super dealloc];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [(ECCodeView *)self.view showCompletions];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    [(ECCodeView *)self.view showCompletions];
}

@end
