//
//  SidebarController.m
//  edit
//
//  Created by Uri Baghin on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SidebarController.h"
#import "Client.h"

@interface SidebarController ()
{
    id _observer;
}
- (void)_setup;
@end

@implementation SidebarController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (void)_setup
{
    _observer = [[NSNotificationCenter defaultCenter] addObserverForName:(NSString *)ClientCurrentProjectChangedNotification object:[Client sharedClient] queue:nil usingBlock:^(NSNotification *__strong note) {
        self.selectedIndex = 1;
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}

@end
