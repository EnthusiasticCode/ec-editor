//
//  FileSystemDirectory.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemItem.h"

@interface FileSystemDirectory : FileSystemItem

// Get the receiver's children.
//
// options            - A mask of NSDirectoryEnumerationOptions with which to
//                      filter the children sent by the signal. May not include
//                      NSDirectoryEnumerationSkipsPackageDescendants.
// abbreviationSignal - An optional signal that sends strings with which to sort
//                      and filter the children sent by the signal.
//
// Returns a signal that sends the children of the receiver as they change.
- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(RACSignal *)abbreviationSignal;

// Equivalent to -childrenWithOptions:options filteredByAbbreviation:nil
- (RACSignal *)childrenWithOptions:(NSDirectoryEnumerationOptions)options;

// Equivalent to -childrenWithOptions:
// NSDirectoryEnumerationSkipsSubdirectoryDescendants |
// NSDirectoryEnumerationSkipsHiddenFiles.
- (RACSignal *)childrenFilteredByAbbreviation:(RACSignal *)abbreviationSignal;

// Equivalent to -childrenFilteredByAbbreviation:nil
- (RACSignal *)children;

@end
