//
//  FileSystemItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import <Foundation/Foundation.h>

@class RACPropertySubject, FileSystemDirectory;

@interface FileSystemItem : NSObject

// Returns a signal that sends the item at `url`, then completes.
//
// Note that if the item doesn't exist on the file system, it won't be possible
// to create it with the item returned from this call.
+ (RACSignal *)itemWithURL:(NSURL *)url;

// Returns a signal that sends the URL of the receiver.
@property (nonatomic, strong, readonly) RACSignal *url;

// Returns a signal that sends the name of the receiver.
@property (nonatomic, strong, readonly) RACSignal *name;

// Returns a signal that sends the parent directory of the receiver.
@property (nonatomic, strong, readonly) RACSignal *parent;

@end

@interface FileSystemItem (FileManagement)

// Creates the receiver if it doesn't exist on it's persistence mechanism.
//
// Returns a signal that sends the newly created item and completes.
- (RACSignal *)create;

// Moves the receiver to the given directory.
//
// destination   - An optional FileSystemDirectory to which the receiver is
//                 moved.
// newName       - An optional name to rename the file to.
// shouldReplace - Indicates if the operation should replace any existing file.
//
// Returns a signal that sends the moved FileSystemItem and completes.
- (RACSignal *)moveTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Copy the receiver to the given directory.
//
// destination   - An optional FileSystemDirectory to which the receiver is
//                 copied.
// newName       - An optional name to rename the file to.
// shouldReplace - Indicates if the operation should replace any existing file.
//
// Returns a signal that sends the newly copied FileSystemItem and completes.
- (RACSignal *)copyTo:(FileSystemDirectory *)destination withName:(NSString *)newName replaceExisting:(BOOL)shouldReplace;

// Equivalent to -moveTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)moveTo:(FileSystemDirectory *)destination;

// Equivalent to -copyTo:destination withName:nil replaceExisting:YES.
- (RACSignal *)copyTo:(FileSystemDirectory *)destination;

// Equivalent to -moveTo:nil withName:newName replaceExisting:YES.
- (RACSignal *)renameTo:(NSString *)newName;

// Duplicates the receiver.
//
// Returns a signal that sends the duplicate and completes.
- (RACSignal *)duplicate;

// Deletes the receiver.
//
// Returns a signal that sends the deleted item and completed.
- (RACSignal *)delete;

@end

@interface FileSystemItem (ExtendedAttributes)

// Returns a property subject for the receiver's extended attribute identified
// by `key`.
- (RACPropertySubject *)extendedAttributeForKey:(NSString *)key;

@end
