//
//  ECCarpetView.m
//  edit
//
//  Created by Nicola Peduzzi on 17/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCarpetView.h"
#import "ECCarpetPanelView.h"

NSString* const ECCarpetPanelMain = @"PanelMain";
NSString* const ECCarpetPanelOne = @"PanelOne";
NSString* const ECCarpetPanelTwo = @"PanelTwo";

@interface ECCarpetView ()

// TODO rethink this methods to reduce computation in normal bahaviour
- (void)resetAllPanelsFrame;
- (void)setFrameForPanelNamed:(NSString *)name;

@end

@implementation ECCarpetView

@synthesize delegate;
@synthesize direction;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {
        panelsDictionary = [[NSMutableDictionary dictionaryWithCapacity:3] retain];
        ECCarpetPanelView * panel = [[ECCarpetPanelView alloc] initWithFrame:self.bounds];
        panel.panelPosition = 0;
        panel.panelSize = 0;
        panelMain = panel;
        // DEBUG
        panel.backgroundColor = [UIColor redColor];
        [panelsDictionary setObject:panel forKey:ECCarpetPanelMain];
        [super addSubview:panel];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame panelNames:(NSArray *)panels direction:(ECCarpetViewDirection)dir
{
    if ((self = [self initWithFrame:frame]))
    {
        direction = dir;
        UIView * panel;
        NSString * panelName;
        CGFloat defaultSize = 1.0 / ([panels count] + 1);
        for (int i = 0; i != [panels count]; ++i)
        {
            panelName = (NSString *)[panels objectAtIndex:i];
            if ([panelName isKindOfClass:[NSString class]])
            {
                panel = [self addPanelWithName:panelName 
                                          size:defaultSize 
                                          position:(NSInteger)(i > [panels count] / 2)];
            }
        }
    }
    return self;
}

- (void)addSubview:(UIView *)view 
{
    // Disabling this method. One should use
    // addSubview:toPanel: instead.
}

- (void)setDirection:(ECCarpetViewDirection)dir
{
    if (dir != direction)
    {
        self.direction = dir;
        [self resetAllPanelsFrame];
    }
}

- (UIView*)panelWithName:(NSString*)name
{
    return (UIView*)[panelsDictionary objectForKey:name];
}

- (UIView*)addPanelWithName:(NSString *)name size:(CGFloat)size position:(NSInteger)position
{
    ECCarpetPanelView * panel = (ECCarpetPanelView *)[panelsDictionary objectForKey:name];
    if (panel == nil)
    {
        panel = [[ECCarpetPanelView alloc] init];
        panel.panelSize = size;
        panel.panelPosition = position ? position : -1;
        [panelsDictionary setObject:panel forKey:name];
        [super addSubview:panel];
        [self resetAllPanelsFrame];
    }
    return panel;
}

- (CGFloat)panelSizeForPanelNamed:(NSString *)name
{
    return [(ECCarpetPanelView*)[panelsDictionary objectForKey:name] panelSize];
}

- (void)setPanelSize:(CGFloat)size forPanelNamed:(NSString *)name
{
    [(ECCarpetPanelView*)[panelsDictionary objectForKey:name] setPanelSize:size];
}

- (void)addSubview:(UIView *)view toPanelNamed:(NSString *)name
{
    [[self panelWithName:name] addSubview:view];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc 
{
    [panelsDictionary release];
    [sortedPanels release];
    [super dealloc];
}

#pragma mark Private messages

- (void)resetAllPanelsFrame
{
    [sortedPanels release];
    sortedPanels = [[[self subviews] sortedArrayUsingComparator:^(id obj1, id obj2) { 
        if (obj1 == obj2)
            return NSOrderedSame;
        return ((ECCarpetPanelView *)obj1).panelPosition < ((ECCarpetPanelView *)obj2).panelPosition
        ? NSOrderedAscending
        : NSOrderedDescending;
    }] retain];
    
    for(id n in [panelsDictionary keyEnumerator])
    {
        [self setFrameForPanelNamed:(NSString *)n];
    }
}

- (void)setFrameForPanelNamed:(NSString *)name
{
    CGRect frame = CGRectMake(0, 0, 0, 0);
    // Control that required panel exists
    ECCarpetPanelView * panel = (ECCarpetPanelView *)[panelsDictionary objectForKey:name];
    if (panel == nil)
        return;
    //
    ECCarpetPanelView * ii;
    NSEnumerator * i;
    // Main panel special frame (auto size)
    if ([ECCarpetPanelMain isEqualToString:name])
    {
        i = [sortedPanels objectEnumerator];
        CGFloat before = 0, after = 0;
        while ((ii = (ECCarpetPanelView*)[i nextObject]) 
               && !panel.hidden)
        {
            if (ii == panel)
                continue;
            if (ii.panelPosition < 0)
                before += [ii panelSizeInUnits];
            else
                after += [ii panelSizeInUnits];
        }
        if (self.direction == ECCarpetHorizontal)
        {
            frame.origin.x = before;
            frame.size.width = self.bounds.size.width - before - after;
            frame.size.height = self.bounds.size.height;
        }
        else
        {
            frame.origin.y = before;
            frame.size.width = self.bounds.size.width;
            frame.size.height = self.bounds.size.height - before - after;
        }
    }
    // Hodizontal disposition frames
    else if (self.direction == ECCarpetHorizontal)
    {
        CGFloat sign = 1;
        frame.size.width = [panel panelSizeInUnits];
        frame.size.height = self.bounds.size.height;
        if (panel.panelPosition < 0)
        {
            i = [sortedPanels objectEnumerator];
        }
        else
        {
            i = [sortedPanels reverseObjectEnumerator];
            frame.origin.x -= frame.size.width;
            sign = -1;
        }
        while ((ii = (ECCarpetPanelView*)[i nextObject]) 
               && panel != ii
               && !panel.hidden)
        {
            frame.origin.x += sign * [ii panelSizeInUnits];
        }
    }
    // Vertical disposition frames
    else
    {
        CGFloat sign = 1;
        frame.size.width = self.bounds.size.width;
        frame.size.height = [panel panelSizeInUnits];
        if (panel.panelPosition < 0)
        {
            i = [sortedPanels objectEnumerator];
        }
        else
        {
            i = [sortedPanels reverseObjectEnumerator];
            frame.origin.y -= frame.size.height;
            sign = -1;
        }
        while ((ii = (ECCarpetPanelView*)[i nextObject]) 
               && panel != ii
               && !panel.hidden)
        {
            frame.origin.y += sign * [ii panelSizeInUnits];
        }
    }
    //
    panel.frame = frame;
}


@end
