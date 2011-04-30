//
//  ECMutableDictionary.m
//  edit
//
//  Created by Uri Baghin on 4/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECMutableDictionary.h"

@interface ECMutableDictionary ()
{
    CFMutableDictionaryRef _directDictionary;
    CFMutableDictionaryRef _inverseDictionary;
}
@end

@implementation ECMutableDictionary

- (void)dealloc
{
    CFRelease(_directDictionary);
    CFRelease(_inverseDictionary);
    [super dealloc];
}

- (id)init
{
    CFDictionaryKeyCallBacks directKeyCallBacks = {0, NULL, NULL, kCFTypeDictionaryKeyCallBacks.copyDescription, kCFTypeDictionaryKeyCallBacks.equal, kCFTypeDictionaryKeyCallBacks.hash};
    CFDictionaryKeyCallBacks inverseKeyCallBacks = {0, NULL, NULL, kCFTypeDictionaryKeyCallBacks.copyDescription, NULL, NULL};
    CFDictionaryValueCallBacks valueCallBacks = {0, NULL, NULL, kCFTypeDictionaryValueCallBacks.copyDescription, NULL};
    _directDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &directKeyCallBacks, &valueCallBacks);
    _inverseDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &inverseKeyCallBacks, &valueCallBacks);
    return self;
}

- (id)initWithObjects:(id *)objects forKeys:(id *)keys count:(NSUInteger)count
{
    self = [self init];
    for (NSUInteger i = 0; i < count; ++i)
    {
        if (objects[i] == nil || keys[i] == nil)
        {
            CFRelease(_directDictionary);
            CFRelease(_inverseDictionary);
            return nil;
        }
        id key = [keys[i] copy];
        CFDictionarySetValue(_directDictionary, key, objects[i]);
        CFDictionarySetValue(_inverseDictionary, objects[i], key);
    }
    return self;
}

- (NSUInteger)count
{
    return CFDictionaryGetCount(_directDictionary);
}

- (id)objectForKey:(id)key
{
    return CFDictionaryGetValue(_directDictionary, key);
}

- (id)keyForObject:(id)object
{
    return CFDictionaryGetValue(_inverseDictionary, object);
}

- (NSEnumerator *)keyEnumerator
{
    return [(NSDictionary *)_directDictionary keyEnumerator];
}

- (NSEnumerator *)objectEnumerator
{
    return [(NSDictionary *)_inverseDictionary keyEnumerator];
}

- (void)setObject:(id)object forKey:(id)key
{
    if (CFDictionaryGetValue(_directDictionary, key) == object)
        return;
    [object retain];
    id oldKey = CFDictionaryGetValue(_inverseDictionary, object);
    if (oldKey)
    {
        CFDictionaryRemoveValue(_directDictionary, oldKey);
        [oldKey release];
    }
    key = [key copy];
    CFDictionarySetValue(_directDictionary, key, object);
    CFDictionarySetValue(_inverseDictionary, object, key);
    [object release];
}

- (void)removeObjectForKey:(id)key
{
    id object = CFDictionaryGetValue(_directDictionary, key);
    key = CFDictionaryGetValue(_inverseDictionary, object);
    CFDictionaryRemoveValue(_inverseDictionary, object);
    CFDictionaryRemoveValue(_directDictionary, key);
    [key release];
}

@end
