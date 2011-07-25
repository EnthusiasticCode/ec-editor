//
//  ACStateNode.m
//  ArtCode
//
//  Created by Uri Baghin on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateNode.h"
#import "ACStateNodeInternal.h"

@interface ACStateNode ()
@property (nonatomic, getter = isDeleted) BOOL deleted;
@end

@implementation ACStateNode

@synthesize deleted = _deleted;

- (NSURL *)URL
{
    return nil;
}

- (void)setURL:(NSURL *)URL
{
    
}

- (NSString *)name
{
    return nil;
}

- (void)setName:(NSString *)name
{
    
}

- (NSUInteger)index
{
    return NSNotFound;
}

- (void)setIndex:(NSUInteger)index
{
    
}

- (NSUInteger)tag
{
    return 0;
}

- (void)setTag:(NSUInteger)tag
{
    
}

- (NSOrderedSet *)children
{
    return nil;
}

- (id)initWithURL:(NSURL *)URL
{
    return [super init];
}

- (id)initWithObject:(id)object
{
    return [super init];
}

- (void)delete
{
    self.deleted = YES;
}

@end
