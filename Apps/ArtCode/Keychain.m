//
//  Keychain.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 23/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Keychain.h"


@implementation Keychain 

#pragma mark Accessing the keychain

- (NSString *)passwordForServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier
{
    CFTypeRef outDataRef = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                       (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnData,
                                                       (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass, 
                                                       serviceIdentifier, (__bridge id)kSecAttrService,
                                                       accountIdentifier, (__bridge id)kSecAttrAccount, 
                                                       nil], &outDataRef) != noErr)
        return nil;
    
    NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)outDataRef encoding:NSUTF8StringEncoding];
    CFRelease(outDataRef);
    return password;
}

- (BOOL)setPassword:(NSString *)password forServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier
{
    if (![password length])
    {
        return [self removePasswordForServiceWithIdentifier:serviceIdentifier account:accountIdentifier];
    }
    
    NSDictionary *spec = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                          serviceIdentifier, (__bridge id)kSecAttrService,
                          accountIdentifier, (__bridge id)kSecAttrAccount, nil];
    
 
    if([self passwordForServiceWithIdentifier:serviceIdentifier account:accountIdentifier] != nil)
    {
        return !SecItemUpdate((__bridge CFDictionaryRef)spec, (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData]);
    }
    else
    {
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:spec];
        [data setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        return !SecItemAdd((__bridge CFDictionaryRef)data, NULL);
    }
}

- (BOOL)removePasswordForServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier
{ 
    return !SecItemDelete((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                     (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                                                     serviceIdentifier, (__bridge id)kSecAttrService,
                                                     accountIdentifier, (__bridge id)kSecAttrAccount, nil]);
}

#pragma mark Class methods

+ (id)sharedKeychain
{
    static Keychain *_sharedKeychain = nil;
    if (!_sharedKeychain)
        _sharedKeychain = [[Keychain alloc] init];
    return _sharedKeychain;
}

+ (NSString *)sharedKeychainServiceIdentifierWithSheme:(NSString *)scheme host:(NSString *)host port:(NSInteger)port
{
    ECASSERT(scheme && host);
    return port ? [NSString stringWithFormat:@"%@://%@:%d", scheme, host, port] : [NSString stringWithFormat:@"%@://%@", scheme, host];
}

@end
