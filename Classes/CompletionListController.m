//
//  CompletionListController.m
//  edit
//
//  Created by Uri Baghin on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CompletionListController.h"


@implementation CompletionListController


@synthesize resultsList;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
        [self addObserver:self forKeyPath:@"resultsList" options:NSKeyValueObservingOptionNew context:NULL];
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.tableView reloadData];
}

- (void)dealloc {
    [_resultsList release];
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.resultsList)
        return [self.resultsList count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *completion = [tableView dequeueReusableCellWithIdentifier:@"Completion"];
    if (!completion)
    {
        completion = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Completion"];
    }
    NSLog(@"%@", self.resultsList);
    completion.textLabel.text = [self.resultsList objectAtIndex:(indexPath.row)];
    return completion;
}

#pragma mark -
#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate completeWithString:[self.resultsList objectAtIndex:indexPath.row]];
}

@end
