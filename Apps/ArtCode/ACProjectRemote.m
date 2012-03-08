//
//  ACProjectRemote.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectRemote.h"
#import "ACProjectItem+Internal.h"

@interface ACProjectRemote ()

- (NSURL *)_URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSNumber *)port user:(NSString *)user;

@end

@implementation ACProjectRemote {
    NSURL *_URL;
}

#pragma mark - Properties

@synthesize name = _name;

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector == @selector(scheme)
        || aSelector == @selector(host)
        || aSelector == @selector(port)
        || aSelector == @selector(user))
        return _URL;
    return nil;
}

- (void)setScheme:(NSString *)scheme
{
    if ([scheme isEqualToString:_URL.scheme])
        return;
    _URL = [self _URLWithScheme:scheme host:_URL.host port:_URL.port user:_URL.user];
}

- (void)setHost:(NSString *)host
{
    if ([host isEqualToString:_URL.host])
        return;
    _URL = [self _URLWithScheme:_URL.scheme host:host port:_URL.port user:_URL.user];
}

- (void)setPort:(NSNumber *)port
{
    if ([port isEqualToNumber:_URL.port])
        return;
    _URL = [self _URLWithScheme:_URL.scheme host:_URL.host port:port user:_URL.user];
}

- (void)setUser:(NSString *)user
{
    if ([user isEqualToString:_URL.user])
        return;
    _URL = [self _URLWithScheme:_URL.scheme host:_URL.host port:_URL.port user:user];
}

#pragma mark - Initialization

- (id)initWithProject:(ACProject *)project name:(NSString *)name scheme:(NSString *)scheme host:(NSString *)host
{
    self = [super initWithProject:project];
    if (!self)
        return nil;
    ECASSERT(name);
    ECASSERT(scheme);
    ECASSERT(host);
    _name = name;
    _URL = [self _URLWithScheme:scheme host:host port:nil user:nil];
    return self;
}

- (id)initWithProject:(ACProject *)project
{
    ECASSERT(NO); // Not the designed initalizer
}

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    _name = [plistDictionary objectForKey:@"name"];
    if (!_name)
        return nil;
    _URL = [NSURL URLWithString:[plistDictionary objectForKey:@"url"]];
    if (!_URL)
        return nil;
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:_name forKey:@"name"];
    [plist setObject:_URL forKey:@"url"];
    return plist;
}

#pragma mark - Private Methods

- (NSURL *)_URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSNumber *)port user:(NSString *)user
{
    ECASSERT([scheme length]);
    ECASSERT([host length]);
    NSString *urlstring = [user length] ? [NSString stringWithFormat:@"%@://%@@%@", scheme, user, host] : [NSString stringWithFormat:@"%@://%@", scheme, host];
    return [NSURL URLWithString:port ? [NSString stringWithFormat:@"%@:%@", urlstring, port] : urlstring];
}

@end
