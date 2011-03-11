//
//  ECPersistentDocument.h
//  edit
//
//  Created by Uri Baghin on 2/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECDocument.h"
@class NSManagedObjectContext;


@interface ECPersistentDocument : ECDocument {
@private
    
}
- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error;
- (NSManagedObjectContext *)managedObjectContext;
- (id)managedObjectModel;


@end
