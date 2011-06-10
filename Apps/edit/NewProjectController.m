//
//  AddProjectController.m
//  edit
//
//  Created by Uri Baghin on 5/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NewProjectController.h"

@interface NewProjectController ()
@property (nonatomic, strong) NSMutableArray *foundServers;
@property (nonatomic, strong) NSNetServiceBrowser *sshBrowser;
- (void)handleError:(NSNumber *)error;
@end

@implementation NewProjectController

@synthesize foundServers;
@synthesize sshBrowser;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.foundServers = [NSMutableArray array];
    self.sshBrowser = [[NSNetServiceBrowser alloc] init];
    [self.sshBrowser setDelegate:self];
    [self.sshBrowser searchForServicesOfType:@"_ssh._tcp" inDomain:@""];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.sshBrowser stop];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Bonjour";
    else if (section == 2)
        return @"Manual";
    else
        return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    else if (section == 1)
        return [self.foundServers count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0)
        cell.textLabel.text = @"Cancel";
    
    if (indexPath.section == 1)
        cell.textLabel.text = [[self.foundServers objectAtIndex:indexPath.row] hostName];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - NSNetServiceBrowser delegate

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"will search");
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"did stop search");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict
{
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.foundServers addObject:aNetService];
    [aNetService resolveWithTimeout:0.0];
    if(!moreComing)
        [self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.foundServers removeObject:aNetService];
    if(!moreComing)
        [self.tableView reloadData];
}

- (void)handleError:(NSNumber *)error
{
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
}

@end
