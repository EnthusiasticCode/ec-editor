//
//  ACProjectRemote.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectRemote.h"
#import "ACProjectItem+Internal.h"

#import "ACProject.h"
#import "Keychain.h"

@interface ACProjectRemote ()

- (NSURL *)_URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSNumber *)port user:(NSString *)user;

@end

@interface ACProject (Remotes)

- (void)didRemoveRemote:(ACProjectRemote *)remote;

@end

@implementation ACProjectRemote {
    NSURL *_URL;
}

#pragma mark - Properties

@synthesize name = _name;
@dynamic scheme, host, port, user;

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

- (NSString *)password
{
    return [[Keychain sharedKeychain] passwordForServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_URL.scheme host:_URL.host port:[_URL.port integerValue]] account:_URL.user];
}

- (void)setPassword:(NSString *)password
{
    if (!_URL.user)
        return;
    [[Keychain sharedKeychain] setPassword:password forServiceWithIdentifier:[Keychain sharedKeychainServiceIdentifierWithSheme:_URL.scheme host:_URL.host port:[_URL.port integerValue]] account:_URL.user];
}

#pragma mark - Initialization

- (id)initWithProject:(ACProject *)project name:(NSString *)name URL:(NSURL *)remoteURL
{
    self = [super initWithProject:project propertyListDictionary:nil];
    if (!self)
        return nil;
    _URL = remoteURL;
    if (!_URL)
        return nil;
    _name = name;
    if (![_name length])
        _name = _URL.host;
    return self;
}

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super initWithProject:project propertyListDictionary:plistDictionary];
    if (!self)
        return nil;
    _URL = [NSURL URLWithString:[plistDictionary objectForKey:@"url"]];
    if (!_URL)
        return nil;
    _name = [plistDictionary objectForKey:@"name"];
    if (![_name length])
        _name = _URL.host;
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    NSMutableDictionary *plist = [[super propertyListDictionary] mutableCopy];
    [plist setObject:_name forKey:@"name"];
    [plist setObject:[_URL absoluteString] forKey:@"url"];
    return plist;
}

#pragma mark - Item methods

- (NSURL *)URL
{
    return _URL;
}

- (ACProjectItemType)type
{
    return ACPRemote;
}

- (void)remove
{
    [self.project didRemoveRemote:self];
    [super remove];
}

#pragma mark - Private Methods

- (NSURL *)_URLWithScheme:(NSString *)scheme host:(NSString *)host port:(NSNumber *)port user:(NSString *)user
{
    ASSERT([scheme length]);
    ASSERT([host length]);
    NSString *urlstring = [user length] ? [NSString stringWithFormat:@"%@://%@@%@", scheme, user, host] : [NSString stringWithFormat:@"%@://%@", scheme, host];
    return [NSURL URLWithString:port ? [NSString stringWithFormat:@"%@:%@", urlstring, port] : urlstring];
}

@end
