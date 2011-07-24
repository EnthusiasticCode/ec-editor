//
//  ACStateProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateInternal.h"

@interface ACStateProject ()

- (void)handleProjectProxyRenameCommand:(NSNotification *)notification;
- (void)handleProjectProxyDeleteCommand:(NSNotification *)notification;
- (void)handleProjectWillRenameNotification:(NSNotification *)notification;
- (void)handleProjectDidRenameNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification;

@end

@implementation ACStateProject

@synthesize name = _name;

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    [[ACState sharedState] setName:name forProjectWithName:_name];
}

- (NSUInteger)index
{
    return [[ACState sharedState] indexOfProjectWithName:self.name];
}

- (void)setIndex:(NSUInteger)index
{
    [[ACState sharedState] setIndex:index forProjectWithName:self.name];
}

- (UIColor *)color
{
    return [[ACState sharedState] colorForProjectWithName:self.name];
}

- (void)setColor:(UIColor *)color
{
    [[ACState sharedState] setColor:color forProjectWithName:self.name];
}

- (NSURL *)URL
{
    return [NSURL URLWithString:[[ACURLScheme stringByAppendingString:@":/"] stringByAppendingString:[self.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (void)setURL:(NSURL *)URL
{
    ECASSERT([[URL scheme] isEqualToString:ACURLScheme]);
    self.name = [[URL pathComponents] objectAtIndex:0];
}

#pragma mark - Internal Methods

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectProxyRenameCommand:) name:ACProjectProxyRenameCommand object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectProxyDeleteCommand:) name:ACProjectProxyDeleteCommand object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectWillRenameNotification::) name:ACProjectWillRenameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectDidRenameNotification:) name:ACProjectDidRenameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesWillChangeNotification:) name:ACProjectPropertiesWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesDidChangeNotification:) name:ACProjectPropertiesDidChangeNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (ACStateProject *)projectProxyForProjectWithName:(NSString *)name
{
    ACStateProject *proxy = [self alloc];
    proxy = [proxy init];
    proxy->_name = name;
    return proxy;
}

#pragma mark - Notification and command handling

- (void)handleProjectProxyRenameCommand:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"oldName"] isEqualToString:self.name])
        return;
    _name = [[notification userInfo] objectForKey:@"newName"];
}

- (void)handleProjectProxyDeleteCommand:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    [self willChangeValueForKey:@"name"];
    [self willChangeValueForKey:@"URL"];
    [self willChangeValueForKey:@"index"];
    [self willChangeValueForKey:@"color"];
    [self willChangeValueForKey:@"active"];
    _name = nil;
    [self didChangeValueForKey:@"name"];
    [self didChangeValueForKey:@"URL"];
    [self didChangeValueForKey:@"index"];
    [self didChangeValueForKey:@"color"];
    [self didChangeValueForKey:@"active"];
}

- (void)handleProjectWillRenameNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"oldName"] isEqualToString:self.name])
        return;
    [self willChangeValueForKey:@"name"];
    [self willChangeValueForKey:@"URL"];
}

- (void)handleProjectDidRenameNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"newName"] isEqualToString:self.name])
        return;
    [self didChangeValueForKey:@"name"];
    [self didChangeValueForKey:@"URL"];
}

- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self willChangeValueForKey:key];
}

- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self didChangeValueForKey:key];
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [[ACState sharedState] openProjectWithName:self.name withCompletionHandler:completionHandler];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [[ACState sharedState] closeProjectWithName:self.name withCompletionHandler:completionHandler];
}

@end