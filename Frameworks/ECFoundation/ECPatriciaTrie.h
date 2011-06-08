//
//  ECPatriciaTrie.h
//  edit
//
//  Created by Uri Baghin on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    ECPatriciaTrieEnumerationOptionsSkipEndOfWord = 1,
    ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord = 2,
    ECPatriciaTrieEnumerationOptionsSkipWithObject = 4,
    ECPatriciaTrieEnumerationOptionsSkipWithoutObject = 8,
    ECPatriciaTrieEnumerationOptionsSkipDescendants = 16,
    ECPatriciaTrieEnumerationOptionsSkipRoot = 32,
    ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch = 64,
};

typedef NSUInteger ECPatriciaTrieEnumerationOptions;

@interface ECPatriciaTrie : NSObject
@property (nonatomic, weak, readonly) ECPatriciaTrie *parent;
@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong) id object;
@property (nonatomic, getter = isEndOfWord) BOOL endOfWord;

- (NSUInteger)count;
- (NSUInteger)nodeCountWithOptions:(ECPatriciaTrieEnumerationOptions)options;
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (ECPatriciaTrie *)nodeForKey:(NSString *)key;
- (NSArray *)objectsForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options;
- (NSArray *)nodesForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options;
- (void)enumerateObjectsForKeysStartingWithString:(NSString *)string withBlock:(void(^)(id object))block options:(ECPatriciaTrieEnumerationOptions)options;
- (void)enumerateNodesForKeysStartingWithString:(NSString *)string withBlock:(void(^)(ECPatriciaTrie *node))block options:(ECPatriciaTrieEnumerationOptions)options;

@end
