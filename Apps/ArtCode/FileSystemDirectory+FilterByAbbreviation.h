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
/// Equivalent to contentWithOptions:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:abbreviationSubscribable
/// This subscribable does not complete.
- (id<RACSubscribable>)contentFilteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

/// Returns a subscribable that sends the content of the directory as it changes filtered by the abbreviations sent by \a abbreviationSubscribable.
/// This subscribable does not complete.
- (id<RACSubscribable>)contentWithOptions:(NSDirectoryEnumerationOptions)options filteredByAbbreviation:(id<RACSubscribable>)abbreviationSubscribable;

@end

@interface NSURL (Abbreviation)

- (NSIndexSet *)hitMask;

@end