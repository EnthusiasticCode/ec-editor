//
//  ACStateNode.m
//  ArtCode
//
//  Created by Uri Baghin on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateNode.h"
#import "ACStateInternal.h"

@interface ACStateNode ()
@property (nonatomic, getter = isDeleted) BOOL deleted;
@end

@implementation ACStateNode

@dynamic URL;
@dynamic name;
@dynamic index;
@dynamic tag;
@dynamic children;
@synthesize deleted = _deleted;

- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (!self)
        return nil;
    self.URL = URL;
    return self;
}

- (void)delete
{
    self.deleted = YES;
}

@end
