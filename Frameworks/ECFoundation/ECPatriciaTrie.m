//
//  ECPatriciaTrie.m
//  edit
//
//  Created by Uri Baghin on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPatriciaTrie.h"

#ifndef NDEBUG
#define ECASSERT(x) assert(x)
#else
#define ECASSERT(x)
#endif

#define ALPHABET_SIZE 39

@interface ECPatriciaTrie ()
{
    ECPatriciaTrie *_children[ALPHABET_SIZE];
}
@property (nonatomic, assign) ECPatriciaTrie *parent;
@property (nonatomic, retain) NSString *key;
static NSUInteger _indexForCharacter(unsigned char character);
static BOOL _characterIsEndOfWord(NSUInteger characterIndex, NSString *string);
- (NSUInteger)_criticalCharacterInKey:(NSString *)key;
- (void)_enumerateNodesWithBlock:(void(^)(ECPatriciaTrie *node))block options:(ECPatriciaTrieEnumerationOptions)options;
- (ECPatriciaTrie *)_deepestDescendantForKey:(NSString *)key;
- (void)_setObject:(id)object forKey:(NSString *)key;
- (void)_remove;
- (ECPatriciaTrie *)_insertNodeForKey:(NSString *)key;
@end

@implementation ECPatriciaTrie

@synthesize parent = _parent;
@synthesize key = _key;
@synthesize object = _object;
@synthesize endOfWord = _isEndOfWord;

- (void)dealloc
{
    self.key = nil;
    self.object = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.endOfWord = YES;
    return self;
}

NSUInteger _indexForCharacter(unsigned char character)
{
    if (character == '@')
        return 0;
    if (character == ':')
        return 1;
    if (character == '_')
        return 2;
    if (character >= '0' && character <= '9')
        return character - 45;
    if (character >= 'a' && character <='z')
        return character - 84;
    if (character >= 'A' && character <= 'Z')
        return character - 52;
    [NSException raise:NSInvalidArgumentException format:@"Passed a string that is not a valid identifier or method signature as key to ECPatriciaTrie"];
    return -1;
}

BOOL _characterIsEndOfWord(NSUInteger characterIndex, NSString *string)
{
    ECASSERT(characterIndex < [string length]);
    if (characterIndex == [string length] - 1)
        return YES;
    unsigned char character = [string characterAtIndex:characterIndex];
    unsigned char nextCharacter = [string characterAtIndex:characterIndex + 1];
    if (character >= 'a' && character <= 'z' && (nextCharacter < 'a' || nextCharacter > 'z'))
        return YES;
    return NO;
}

- (NSUInteger)_criticalCharacterInKey:(NSString *)key
{
    NSUInteger criticalCharacter;
    NSUInteger shortestKeyLenght = MIN([key length], [self.key length]);
    for (criticalCharacter = [self.parent.key length]; criticalCharacter < shortestKeyLenght; ++criticalCharacter)
        if (tolower([key characterAtIndex:criticalCharacter]) != tolower([self.key characterAtIndex:criticalCharacter]))
            break;
    return criticalCharacter;
}
- (void)_enumerateNodesWithBlock:(void (^)(ECPatriciaTrie *))block options:(ECPatriciaTrieEnumerationOptions)options
{
    ECASSERT(block);
    if (!(options & ECPatriciaTrieEnumerationOptionsSkipRoot))
        block(self);
    for (NSUInteger i = 0; i < ALPHABET_SIZE; ++i)
    {
        ECPatriciaTrie *child = _children[i];
        if (!child)
            continue;
        if (options & ECPatriciaTrieEnumerationOptionsSkipEndOfWord && child.endOfWord)
            continue;
        if (options & ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord && !child.endOfWord)
            continue;
        if (options & ECPatriciaTrieEnumerationOptionsSkipWithObject && child.object)
            continue;
        if (options & ECPatriciaTrieEnumerationOptionsSkipWithoutObject && !child.object)
            continue;
        block(child);
        if (options & ECPatriciaTrieEnumerationOptionsSkipDescendants)
            continue;
        [child _enumerateNodesWithBlock:block options:options];
    }
}

- (NSUInteger)count
{
    return [self nodeCountWithOptions:ECPatriciaTrieEnumerationOptionsSkipWithoutObject];
}

- (NSUInteger)nodeCountWithOptions:(ECPatriciaTrieEnumerationOptions)options
{
    __block NSUInteger count;
    [self _enumerateNodesWithBlock:^(ECPatriciaTrie *child) {
        ++count;
    } options:options];
    return count;
}

- (id)objectForKey:(NSString *)key
{
    ECASSERT(key);
    return [self nodeForKey:key].object;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    ECASSERT(key);
    [[self _deepestDescendantForKey:key] _setObject:object forKey:key];
}

- (ECPatriciaTrie *)_deepestDescendantForKey:(NSString *)key
{
    ECASSERT(key);
    NSUInteger criticalCharacter = [self _criticalCharacterInKey:key];
    if (criticalCharacter < [self.key length])
        return self;
    ECPatriciaTrie *child = nil;
    if (criticalCharacter < [key length])
        child = _children[_indexForCharacter([key characterAtIndex:criticalCharacter])];
    if (!child)
        return self;
    return [child _deepestDescendantForKey:key];
}

- (void)_setObject:(id)object forKey:(NSString *)key
{
    ECASSERT(key);
    NSUInteger criticalCharacter = [self _criticalCharacterInKey:key];
    if (criticalCharacter == [key length])
        if (object)
            return [self setObject:object];
        else
            return [self _remove];
    if (object)
        [self _insertNodeForKey:key].object = object;
}

- (void)_remove
{
    if (!self.parent)
        return [self setObject:nil];
    NSUInteger numChildren = 0;
    ECPatriciaTrie *child = nil;
    for (NSUInteger i = 0; i < ALPHABET_SIZE; ++i)
        if (_children[i])
        {
            ++numChildren;
            if (!child)
                child = _children[i];
        }
    if (numChildren > 1)
        return [self setObject:nil];
    NSUInteger parentCriticalCharacter = [self.parent.key length];
    NSUInteger indexInParent = _indexForCharacter([self.key characterAtIndex:parentCriticalCharacter]);
    if (!numChildren)
    {
        if (_characterIsEndOfWord(parentCriticalCharacter, self.key))
        {
            BOOL isEndOfWord = NO;
            for (NSUInteger i = 0; i < ALPHABET_SIZE; ++i)
                if (_characterIsEndOfWord(parentCriticalCharacter, self.parent->_children[i].key))
                {
                    isEndOfWord = YES;
                    break;
                }
            self.parent.endOfWord = isEndOfWord;
        }
        self.parent->_children[indexInParent] = nil;
    }
    else
    {
        self.parent->_children[indexInParent] = child;
        child.parent = self.parent;
    }
    [self release];
}

- (ECPatriciaTrie *)_insertNodeForKey:(NSString *)key
{
    ECASSERT(key);
    NSUInteger criticalCharacter = [self _criticalCharacterInKey:key];
    ECPatriciaTrie *child = [[ECPatriciaTrie alloc] init];
    child.key = key;
    if (criticalCharacter == [self.key length])
    {
        child.parent = self;
        _children[_indexForCharacter([key characterAtIndex:criticalCharacter])] = child;
        return child;
    }
    ECPatriciaTrie *parent = [[ECPatriciaTrie alloc] init];
    parent.key = [self.key substringToIndex:criticalCharacter];
    parent.parent = self.parent;
    parent->_children[_indexForCharacter([key characterAtIndex:criticalCharacter])] = child;
    parent->_children[_indexForCharacter([self.key characterAtIndex:criticalCharacter])] = self;
    parent.endOfWord = _characterIsEndOfWord(criticalCharacter, key) || _characterIsEndOfWord(criticalCharacter, self.key);
    NSUInteger parentCriticalIndex = [self.parent.key length];
    self.parent->_children[_indexForCharacter([key characterAtIndex:parentCriticalIndex])] = parent;
    self.parent = parent;
    child.parent = parent;
    return child;
}

- (ECPatriciaTrie *)nodeForKey:(NSString *)key
{
    ECASSERT(key);
    if ([self.key isEqualToString:key])
        return self;
    NSUInteger criticalCharacter = [self.key length];
    if (criticalCharacter >= [key length])
        return nil;
    ECPatriciaTrie *child = _children[_indexForCharacter([key characterAtIndex:criticalCharacter])];
    if (!child)
        return nil;
    return [child nodeForKey:key];
}

- (NSArray *)objectsForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options
{
    NSMutableArray *array = [NSMutableArray array];
    [[self _deepestDescendantForKey:string] _enumerateNodesWithBlock:^(ECPatriciaTrie *child) {
        [array addObject:child.object];
    } options:options | ECPatriciaTrieEnumerationOptionsSkipWithoutObject];
    return array;
}

- (NSArray *)nodesForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options
{
    NSMutableArray *array = [NSMutableArray array];
    [[self _deepestDescendantForKey:string] _enumerateNodesWithBlock:^(ECPatriciaTrie *child) {
        [array addObject:child];
    } options:options];
    return array;
}

@end
