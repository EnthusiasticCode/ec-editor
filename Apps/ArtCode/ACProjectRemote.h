//
//  ACProjectRemote.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"

@interface ACProjectRemote : ACProjectItem

- (id)initWithProject:(ACProject *)project name:(NSString *)name scheme:(NSString *)scheme host:(NSString *)host;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSNumber *port;
@property (nonatomic, strong) NSString *user;

/// The password is saved using keychain for the receiver's service and user.
@property (nonatomic, strong) NSString *password;

@end
