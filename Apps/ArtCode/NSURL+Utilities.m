//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSURL+Utilities.h"
#import "NSString+UUID.h"
#import "NSString+Utilities.h"

@interface NSURL (Additions_Internal)

+ (NSArray *)_packageExtensions;

@end

@implementation NSURL (Additions)

+ (NSURL *)applicationDocumentsDirectory {
  return [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
}

+ (NSURL *)applicationLibraryDirectory {
  return [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0]];
}

+ (NSURL *)temporaryDirectory {
  NSString *tempDirectoryTemplate =
  [NSTemporaryDirectory() stringByAppendingPathComponent:@"actmpdir.XXXXXX"];
  const char *tempDirectoryTemplateCString =
  [tempDirectoryTemplate fileSystemRepresentation];
  char *tempDirectoryNameCString =
  (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
  strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
  
  char *result = mkdtemp(tempDirectoryNameCString);
  if (!result)
  {
    // handle directory creation failure
  }
  
  NSString *tempDirectoryPath =
  [[NSFileManager defaultManager]
   stringWithFileSystemRepresentation:tempDirectoryNameCString
   length:strlen(result)];
  free(tempDirectoryNameCString);
  
  return [NSURL fileURLWithPath:tempDirectoryPath isDirectory:YES];
}

+ (NSURL *)temporaryFileURL {
  NSString *tempFileTemplate =
  [NSTemporaryDirectory() stringByAppendingPathComponent:@"actmpfile.XXXXXX"];
  const char *tempFileTemplateCString =
  [tempFileTemplate fileSystemRepresentation];
  char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
  strcpy(tempFileNameCString, tempFileTemplateCString);
  int fileDescriptor = mkstemp(tempFileNameCString);
  
  if (fileDescriptor == -1)
  {
    // handle file creation failure
  }
  
  // This is the file name if you need to access the file by name, otherwise you can remove
  // this line.
  NSString *tempFileName =
  [[NSFileManager defaultManager]
   stringWithFileSystemRepresentation:tempFileNameCString
   length:strlen(tempFileNameCString)];
  
  free(tempFileNameCString);
  
  return [NSURL fileURLWithPath:tempFileName isDirectory:NO];
}

- (BOOL)isSubdirectoryDescendantOfDirectoryAtURL:(NSURL *)directoryURL {
  if (![[self absoluteString] hasPrefix:[directoryURL absoluteString]]) {
    return NO;
  }
  return [[self pathComponents] count] != [[directoryURL pathComponents] count] + 1;
}

- (BOOL)isHidden {
  return [[self lastPathComponent] characterAtIndex:0] == L'.';
}

- (BOOL)isHiddenDescendant {
  return !([[[self absoluteString] stringByDeletingLastPathComponent] rangeOfString:@"/."].location == NSNotFound);
}

- (BOOL)isPackage {
  for (NSString *packageExtension in [[self class] _packageExtensions]) {
    if ([[self pathExtension] isEqualToString:packageExtension]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isPackageDescendant {
  NSString *absoluteString = [self absoluteString];
  if ([absoluteString characterAtIndex:[absoluteString length] - 1] == L'/') {
    absoluteString = [absoluteString substringToIndex:[absoluteString length] - 1];
  }
  for (NSString *packageExtension in [[self class] _packageExtensions]) {
    NSRange rangeOfPackageExtension = [absoluteString rangeOfString:[packageExtension stringByAppendingString:@"/"]];
    if (rangeOfPackageExtension.location != NSNotFound) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isDirectory {
  NSNumber *isDirectory;
  if ([self getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL]) {
    return [isDirectory boolValue];
  }
  // Backup by looking with the defaul file manager
  BOOL isDirectoryBool = NO;
  [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectoryBool];
  return isDirectoryBool;
}

- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number {
  return [self.URLByDeletingLastPathComponent URLByAppendingPathComponent:[self.lastPathComponent stringByAddingDuplicateNumber:number]];
}

- (NSString *)prettyPath {
  return [[self path] prettyPath];
}

@end

@implementation NSURL (Additions_Internal)

+ (NSArray *)_packageExtensions {
  static NSArray *packageExtensions = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    packageExtensions = @[@"app", @"tmbundle", @"bundle"];
  });
  return packageExtensions;
}

@end
