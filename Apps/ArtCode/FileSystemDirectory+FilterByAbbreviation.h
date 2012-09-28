//
//  FileSystemDirectory+FilterByAbbreviation.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemDirectory.h"

@interface FileSystemDirectory (FilterByAbbreviation)

/// Returns a subscribable that sends the contents of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSubscribable
/// This subscribable does not complete.
- (id<RACSubscribable>)contentFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

/// Returns a subscribable that sends the content of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// Sends tuples where the first element is the url and the second element is the filter hitmask, if applicable
/// This subscribable does not complete.
- (id<RACSubscribable>)contentWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

@end
