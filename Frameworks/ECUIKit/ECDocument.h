//
//  ECDocument.h
//  edit
//
//  Created by Uri Baghin on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ECDocument : NSObject
@property (nonatomic, retain) NSString *path;
@property (nonatomic, getter = isDocumentEdited) BOOL documentEdited;
@property (nonatomic, readonly) NSString *displayName;
- (BOOL)readFromPath:(NSString *)path error:(NSError **)error;
- (BOOL)writeToPath:(NSString *)path error:(NSError **)error;
@end
