//
//  FileSystemFile.h
//  ArtCode
//
//  Created by Uri Baghin on 10/01/2013.
//
//

#import "FileSystemItem.h"

@class RACPropertySubject;

@interface FileSystemFile : FileSystemItem

// Returns a property subject for the receiver's encoding.
@property (nonatomic, strong, readonly) RACPropertySubject *encodingSubject;

// Returns a property subject for the receiver's content.
@property (nonatomic, strong, readonly) RACPropertySubject *contentSubject;

// Saves the receiver to it's persistence mechanism.
//
// Returns a signal that sends the saved item and completes.
- (RACSignal *)save;

@end
