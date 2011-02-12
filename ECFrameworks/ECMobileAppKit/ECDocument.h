//
//  ECDocument.h
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECDocument : NSObject {
@private
    
}
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSString *fileType;
@property (nonatomic, retain) NSDate *fileModificationDate;
@property (nonatomic, getter = isDocumentEdited) BOOL documentEdited;
@property (nonatomic, readonly) NSString *displayName;

- (id)initWithType:(NSString *)fileType error:(NSError **)error;
- (id)initWithContentsOfURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error;
- (BOOL)readFromURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)fileType error:(NSError **)error;
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)fileType error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error;
- (NSFileWrapper *)fileWrapperOfType:(NSString *)fileType error:(NSError **)error;
- (NSData *)dataOfType:(NSString *)fileType error:(NSError **)error;

+ (BOOL)isNativeType:(NSString *)fileType;
+ (NSArray *)readableTypes;
+ (NSArray *)writableTypes;

@end
