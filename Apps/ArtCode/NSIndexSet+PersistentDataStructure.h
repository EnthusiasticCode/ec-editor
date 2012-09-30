//
//  NSIndexSet+PersistentDataStructure.h
//  ArtCode
//
//  Created by Uri Baghin on 9/30/12.
//
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (PersistentDataStructure)

- (instancetype)indexSetByAddingIndex:(NSUInteger)index;
- (instancetype)indexSetByRemovingIndex:(NSUInteger)index;

@end
