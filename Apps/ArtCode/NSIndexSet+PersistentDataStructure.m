//
//  NSIndexSet+PersistentDataStructure.m
//  ArtCode
//
//  Created by Uri Baghin on 9/30/12.
//
//

#import "NSIndexSet+PersistentDataStructure.h"

@implementation NSIndexSet (PersistentDataStructure)

- (instancetype)indexSetByAddingIndex:(NSUInteger)index {
  NSMutableIndexSet *indexSet = self.mutableCopy;
  [indexSet addIndex:index];
  return indexSet.copy;
}

- (instancetype)indexSetByRemovingIndex:(NSUInteger)index {
  NSMutableIndexSet *indexSet = self.mutableCopy;
  [indexSet removeIndex:index];
  return indexSet.copy;
}

@end
