//
//  ECPatriciaTrie.m
//  edit
//
//  Created by Uri Baghin on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPatriciaTrie.h"

#define ALPHABET_SIZE 39

@interface ECPatriciaTrie ()
{
    ECPatriciaTrie *_children[ALPHABET_SIZE];
}
@property (nonatomic, weak) ECPatriciaTrie *parent;
@property (nonatomic, strong) NSString *key;
static NSUInteger _indexForCharacter(unsigned char character);
static BOOL _characterIsStartOfWord(NSUInteger characterIndex, NSString *string);
- (NSUInteger)_criticalCharacterInKey:(NSString *)key;
static BOOL _skipNodeForOptions(ECPatriciaTrie *node, ECPatriciaTrieEnumerationOptions options);
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

BOOL _characterIsStartOfWord(NSUInteger characterIndex, NSString *string)
{
    ECASSERT(characterIndex < [string length]);
    if (!characterIndex)
        return YES;
    unsigned char character = [string characterAtIndex:characterIndex];
    unsigned char previousCharacter = [string characterAtIndex:characterIndex - 1];
    if (character >= 'A' && character <= 'Z' && previousCharacter >= 'a' && previousCharacter <= 'z')
        return YES;
    if (character != '_' && previousCharacter == '_')
        return YES;
    if (character != '@' && previousCharacter == '@')
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

BOOL _skipNodeForOptions(ECPatriciaTrie *node, ECPatriciaTrieEnumerationOptions options)
{
    REQUIRE_NOT_NULL(node);
    if (!options)
        return NO;
    if (options & ECPatriciaTrieEnumerationOptionsSkipEndOfWord && node.endOfWord)
        return YES;;
    if (options & ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord && !node.endOfWord)
        return YES;
    if (options & ECPatriciaTrieEnumerationOptionsSkipWithObject && node.object)
        return YES;
    if (options & ECPatriciaTrieEnumerationOptionsSkipWithoutObject && !node.object)
        return YES;
    return NO;
}

- (void)_enumerateNodesWithBlock:(void (^)(ECPatriciaTrie *))block options:(ECPatriciaTrieEnumerationOptions)options
{
    REQUIRE_NOT_NULL(block);
    if (!(options & ECPatriciaTrieEnumerationOptionsSkipRoot))
        if (!_skipNodeForOptions(self, options))
        {
            block(self);
            if (options & ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch)
                return;
        }
    for (NSUInteger i = 0; i < ALPHABET_SIZE; ++i)
    {
        ECPatriciaTrie *child = _children[i];
        if (!child)
            continue;
        if (!_skipNodeForOptions(child, options))
        {
            block(child);
            if (options & ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch)
                continue;
        }
        if (options & ECPatriciaTrieEnumerationOptionsSkipDescendants)
            continue;
        [child _enumerateNodesWithBlock:block options:options | ECPatriciaTrieEnumerationOptionsSkipRoot];
    }
}

- (NSUInteger)count
{
    return [self nodeCountWithOptions:ECPatriciaTrieEnumerationOptionsSkipWithoutObject];
}

- (NSUInteger)nodeCountWithOptions:(ECPatriciaTrieEnumerationOptions)options
{
    __block NSUInteger count = 0;
    [self _enumerateNodesWithBlock:^(ECPatriciaTrie *child) {
        ++count;
    } options:options];
    return count;
}

- (id)objectForKey:(NSString *)key
{
    return [self nodeForKey:key].object;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [[self _deepestDescendantForKey:key] _setObject:object forKey:key];
}

- (ECPatriciaTrie *)_deepestDescendantForKey:(NSString *)key
{
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
    if ([[key lowercaseString] isEqualToString:[self.key lowercaseString]])
        if (object)
        {
            self.object = object;
            self.endOfWord = YES;
            return;
        }
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
        if (_characterIsStartOfWord(parentCriticalCharacter, self.key))
        {
            BOOL isEndOfWord = NO;
            for (NSUInteger i = 0; i < ALPHABET_SIZE; ++i)
                if (_characterIsStartOfWord(parentCriticalCharacter, self.parent->_children[i].key))
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
}

- (ECPatriciaTrie *)_insertNodeForKey:(NSString *)key
{
    REQUIRE_NOT_NULL(key);
    NSUInteger criticalCharacter = [self _criticalCharacterInKey:key];
    if (criticalCharacter == [self.key length])
    {
        ECPatriciaTrie *child = [[ECPatriciaTrie alloc] init];
        child.key = key;
        child.endOfWord = YES;
        child.parent = self;
        _children[_indexForCharacter([key characterAtIndex:criticalCharacter])] = child;
        if (_characterIsStartOfWord(criticalCharacter, key))
            self.endOfWord = YES;
        return child;
    }
    ECPatriciaTrie *parent = [[ECPatriciaTrie alloc] init];
    parent.key = [self.key substringToIndex:criticalCharacter];
    parent.parent = self.parent;
    parent->_children[_indexForCharacter([self.key characterAtIndex:criticalCharacter])] = self;
    parent.endOfWord = YES;
    NSUInteger parentCriticalIndex = [self.parent.key length];
    self.parent->_children[_indexForCharacter([key characterAtIndex:parentCriticalIndex])] = parent;
    self.parent = parent;
    if (criticalCharacter != [key length])
    {
        ECPatriciaTrie *child = [[ECPatriciaTrie alloc] init];
        child.key = key;
        child.endOfWord = YES;
        parent.endOfWord = _characterIsStartOfWord(criticalCharacter, self.key) || _characterIsStartOfWord(criticalCharacter, key);
        parent->_children[_indexForCharacter([key characterAtIndex:criticalCharacter])] = child;
        child.parent = parent;
        return child;
    }
    return parent;
}

- (ECPatriciaTrie *)nodeForKey:(NSString *)key
{
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

- (void)enumerateObjectsForKeysStartingWithString:(NSString *)string withBlock:(void (^)(id))block options:(ECPatriciaTrieEnumerationOptions)options
{
    if (!block)
        return;
    [[self _deepestDescendantForKey:string] _enumerateNodesWithBlock:^(ECPatriciaTrie *child) {
        block(child.object);
    } options:options | ECPatriciaTrieEnumerationOptionsSkipWithoutObject];
}

- (void)enumerateNodesForKeysStartingWithString:(NSString *)string withBlock:(void (^)(ECPatriciaTrie *))block options:(ECPatriciaTrieEnumerationOptions)options
{
    if (!block)
        return;
    [[self _deepestDescendantForKey:string] _enumerateNodesWithBlock:block options:options];
}

@end
