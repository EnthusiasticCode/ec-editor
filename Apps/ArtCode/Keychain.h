//
//  Keychain.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 23/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Keychain : NSObject

+ (id)sharedKeychain;

- (NSString *)passwordForServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier;
- (BOOL)setPassword:(NSString *)password forServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier;
- (BOOL)removePasswordForServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier;

@end
