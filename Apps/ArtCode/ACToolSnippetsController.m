//
//  ACToolSnippetsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 10/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolSnippetsController.h"

@implementation ACToolSnippetsController {
    UIImage *snippetImage;
    UIImage *pasteImage;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    snippetImage = [UIImage imageNamed:@"toolSnippetsSnippet.png"];
    pasteImage = [UIImage imageNamed:@"toolSnippetsPaste.png"];
}

- (void)viewDidUnload
{
    snippetImage = nil;
    pasteImage = nil;
    [super viewDidUnload];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:table cellForRowAtIndexPath:indexPath];
    
    NSUInteger idx = [indexPath indexAtPosition:1];
    if (idx % 2)
    {
        cell.imageView.image = pasteImage; 
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
    else
    {
        cell.imageView.image = snippetImage; 
    }
    
    cell.textLabel.text = @"prova";
    cell.detailTextLabel.text = @"subtext";
    
    return cell;
}

@end
