//
//  ECDictionaryCache.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 25/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDictionaryCache.h"

typedef struct {
    id key;
    id object;
} ECDictionaryCacheEntry;

@interface ECDictionaryCache () {
@private
    ECDictionaryCacheEntry *entries;
    NSUInteger currentInsert;
}
@end

@implementation ECDictionaryCache

@synthesize countLimit;

- (void)setCountLimit:(NSUInteger)limit
{
    if (limit > 0 && limit != countLimit) 
    {
        if (limit < countLimit) 
        {
            for (NSUInteger i = limit; i < countLimit; ++i) 
            {
                [entries[i].object release];
            }
        }
        countLimit = limit;
        entries = (ECDictionaryCacheEntry *)realloc(entries, sizeof(ECDictionaryCacheEntry) * limit);
        // TODO memset
    }
}

- (id)initWithCountLimit:(NSUInteger)limit
{
    if ((self = [super init])) 
    {
        if (limit == 0) 
        {
            limit = 1;
        }
        countLimit = limit;
        entries = (ECDictionaryCacheEntry *)malloc(sizeof(ECDictionaryCacheEntry) * limit);
        memset(entries, 0, sizeof(ECDictionaryCacheEntry) * limit);
    }
    return self;
}

- (void)dealloc
{
    free(entries);
    [super dealloc];
}

- (void)setObject:(id)obj forKey:(id)key
{
    // Release previous entry
    if (entries[currentInsert].object)
    {
        [entries[currentInsert].object release];
    }
    // Insert new entry
    entries[currentInsert].key = key;
    entries[currentInsert].object = [obj retain];
    // Insert point for next insert
    currentInsert++;
    if (currentInsert >= countLimit) 
        currentInsert = 0;
}

- (id)objectForKey:(id)key
{
    for (NSUInteger i = 0; i < countLimit; ++i) 
    {
        if (entries[i].key == key) 
        {
            return entries[i].object;
        }
    }
    return nil;
}

- (void)removeObjectForKey:(id)key
{
    for (NSUInteger i = 0; i < countLimit; ++i) 
    {
        if (entries[i].key == key) 
        {
            [entries[i].object release];
            entries[i].object = nil;
            entries[i].key = nil;
            return;
        }
    }
}

- (void)removeAllObjects
{
    for (NSUInteger i = 0; i < countLimit; ++i) 
    {
        [entries[i].object release];
        entries[i].object = nil;
        entries[i].key = nil;
    }
    currentInsert = 0;
}

@end
