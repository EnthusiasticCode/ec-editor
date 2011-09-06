//
//  ECPatriciaTrie.h
//  edit
//
//  Created by Uri Baghin on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// A Patricia Trie implementation for NSStrings
/// Stores and retrieves objects identified by NSString keys
/// Nodes are added and removed automatically to ensure the trie has no unnecessary nodes, but allows for all key prefix queries


/// Enumeration options for ECPatriciaTrie
/// Can be bitwise ored together
enum
{
    /// Skips nodes that are the last node of a word
    ECPatriciaTrieEnumerationOptionsSkipEndOfWord = 1,
    /// Skips nodes that are not the last node of a word
    ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord = 2,
    /// Skips nodes that have an object associated to them
    ECPatriciaTrieEnumerationOptionsSkipWithObject = 4,
    /// Skips nodes that do not have an object associated to them
    ECPatriciaTrieEnumerationOptionsSkipWithoutObject = 8,
    /// Skips descendants of the matching node
    ECPatriciaTrieEnumerationOptionsSkipDescendants = 16,
    /// Skips the matching node
    ECPatriciaTrieEnumerationOptionsSkipRoot = 32,
    /// Stops the enumeration at the shallowest non-skipped match
    ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch = 64,
};

typedef NSUInteger ECPatriciaTrieEnumerationOptions;

/// An object representing both a node and the trie of which the node is the root
@interface ECPatriciaTrie : NSObject
/// The parent node
@property (nonatomic, weak, readonly) ECPatriciaTrie *parent;
/// The key of the Trie
@property (nonatomic, strong, readonly) NSString *key;
/// The object associated with the key
/// Can be nil
@property (nonatomic, strong) id object;
/// Whether the Trie's key is at the end of a word or not
@property (nonatomic, getter = isEndOfWord) BOOL endOfWord;

/// The number of objects the trie has
- (NSUInteger)count;
/// The number of nodes matching the given enumeration options
- (NSUInteger)nodeCountWithOptions:(ECPatriciaTrieEnumerationOptions)options;
/// Returns the object associated with the given key
- (id)objectForKey:(NSString *)key;
/// Sets the object associated with the given key
- (void)setObject:(id)object forKey:(NSString *)key;
/// The node associated with the given key
- (ECPatriciaTrie *)nodeForKey:(NSString *)key;
/// Returns all objects in the subtrie starting with the given string matching the given enumeration options
- (NSArray *)objectsForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options;
/// Returns all nodes in the subtrie starting with the given string matching the given enumeration options
- (NSArray *)nodesForKeysStartingWithString:(NSString *)string options:(ECPatriciaTrieEnumerationOptions)options;
/// Enumerates all objects in the subtrie starting with the given string matching the given enumeration options with the given block
- (void)enumerateObjectsForKeysStartingWithString:(NSString *)string withBlock:(void(^)(id object))block options:(ECPatriciaTrieEnumerationOptions)options;
/// Enumerates all nodes in the subtrie starting with the given string matching the given enumeration options with the given block
- (void)enumerateNodesForKeysStartingWithString:(NSString *)string withBlock:(void(^)(ECPatriciaTrie *node))block options:(ECPatriciaTrieEnumerationOptions)options;

@end
