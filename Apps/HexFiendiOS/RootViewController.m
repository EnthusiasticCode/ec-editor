//
//  RootViewController.m
//  HexFiendiOS
//
//  Created by Uri Baghin on 5/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"

#import "DetailViewController.h"

@implementation RootViewController
		
@synthesize detailViewController;
@synthesize fileManager;

- (NSFileManager *)fileManager
{
    if (!fileManager)
        fileManager = [[NSFileManager alloc] init];
    return fileManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

		
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self filesInDocumentsDirectory] count];
}

		
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = [[self filesInDocumentsDirectory] objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.detailViewController.detailItem = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[[self filesInDocumentsDirectory] objectAtIndex:indexPath.row]];
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSArray *)filesInDocumentsDirectory
{
    return [self.fileManager contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:NULL];
}

- (void)dealloc
{
    [detailViewController release];
    self.fileManager = nil;
    [super dealloc];
}

@end
