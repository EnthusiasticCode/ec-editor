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
// Returns a signal that sends arrays of tuples each containing one child and
// it's filter hitmask.
- (RACSignal *)childrenSignalWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(RACSignal *)abbreviationSignal;

// Equivalent to -childrenSignalWithOptions:options filteredByAbbreviation:nil
- (RACSignal *)childrenSignalWithOptions:(NSDirectoryEnumerationOptions)options;

// Equivalent to -childrenSignalWithOptions:
// NSDirectoryEnumerationSkipsSubdirectoryDescendants |
// NSDirectoryEnumerationSkipsHiddenFiles.
- (RACSignal *)childrenSignalFilteredByAbbreviation:(RACSignal *)abbreviationSignal;

// Equivalent to -childrenSignalFilteredByAbbreviation:nil
- (RACSignal *)childrenSignal;

@end
