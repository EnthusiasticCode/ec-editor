//
//  FileSystemDirectory+Private.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemDirectory.h"

@interface FileSystemDirectory ()

// Called after `item` has been added to the receiver.
- (void)didAddItem:(FileSystemItem *)item;

// Called after `item` has been removed from the receiver.
- (void)didRemoveItem:(FileSystemItem *)item;

@end
