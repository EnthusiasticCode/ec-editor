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
  if (SecItemCopyMatching((__bridge CFDictionaryRef)@{ (__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue,
                                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, 
                                                     (__bridge id)kSecAttrService: serviceIdentifier,
                                                     (__bridge id)kSecAttrAccount: accountIdentifier }, &outDataRef) != noErr)
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
  
  NSDictionary *spec = @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrService: serviceIdentifier,
                        (__bridge id)kSecAttrAccount: accountIdentifier };
  
  
  if([self passwordForServiceWithIdentifier:serviceIdentifier account:accountIdentifier] != nil)
  {
    return !SecItemUpdate((__bridge CFDictionaryRef)spec, (__bridge CFDictionaryRef)@{ (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding] });
  }
  else
  {
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:spec];
    data[(__bridge id)kSecValueData] = [password dataUsingEncoding:NSUTF8StringEncoding];
    return !SecItemAdd((__bridge CFDictionaryRef)data, NULL);
  }
}

- (BOOL)removePasswordForServiceWithIdentifier:(NSString *)serviceIdentifier account:(NSString *)accountIdentifier
{ 
  return !SecItemDelete((__bridge CFDictionaryRef)@{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                                   (__bridge id)kSecAttrService: serviceIdentifier,
                                                   (__bridge id)kSecAttrAccount: accountIdentifier });
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
  ASSERT(scheme && host);
  return port ? [NSString stringWithFormat:@"%@://%@:%d", scheme, host, port] : [NSString stringWithFormat:@"%@://%@", scheme, host];
}

@end
