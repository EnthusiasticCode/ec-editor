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

- (id)initWithStyle:(UITableViewStyle)style
{
    return [super init];
}

- (void)dealloc {
    self.resultsList = nil;
    [super dealloc];
}

@end
