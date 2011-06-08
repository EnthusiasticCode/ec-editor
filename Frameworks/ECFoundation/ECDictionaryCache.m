//
//  ECDictionaryCache.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 25/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDictionaryCache.h"

@interface ECDictionaryCacheEntry : NSObject
@property (nonatomic, strong) id cachedKey;
@property (nonatomic, strong) id cachedObject;
@end

@implementation ECDictionaryCacheEntry
@synthesize cachedKey;
@synthesize cachedObject;
@end

@interface ECDictionaryCache () {
@private
    NSMutableArray *entries;
    NSUInteger currentInsert;
}
@end

@implementation ECDictionaryCache

@synthesize countLimit;

- (id)initWithCountLimit:(NSUInteger)limit
{
    if ((self = [super init])) 
    {
        if (limit == 0) 
        {
            limit = 1;
        }
        countLimit = limit;
        entries = [NSMutableArray arrayWithCapacity:limit];
    }
    return self;
}

- (void)setObject:(id)obj forKey:(id)key
{
    while (currentInsert >= [entries count])
        [entries addObject:[[[ECDictionaryCacheEntry alloc] init] autorelease]];
    // Insert new entry
    ECDictionaryCacheEntry *entry = [entries objectAtIndex:currentInsert];
    entry.cachedKey = key;
    entry.cachedObject = [obj retain];
    // Insert point for next insert
    currentInsert++;
    if (currentInsert >= countLimit) 
        currentInsert = 0;
}

- (id)objectForKey:(id)key
{
    for (ECDictionaryCacheEntry *entry in entries)
        if (entry.cachedKey == key)
            return entry.cachedObject;
    return nil;
}

- (void)removeObjectForKey:(id)key
{
    for (ECDictionaryCacheEntry *entry in entries)
        if (entry.cachedKey == key)
        {
            entry.cachedKey = nil;
            entry.cachedObject = nil;
            return;
        }
}

- (void)removeAllObjects
{
    for (ECDictionaryCacheEntry *entry in entries)
    {
        entry.cachedKey = nil;
        entry.cachedObject = nil;
    }
    currentInsert = 0;
}

@end
