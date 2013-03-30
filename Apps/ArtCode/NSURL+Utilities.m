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

/* See http://www.faqs.org/rfcs/rfc1738.html */
static NSString *escapeUserOrPassword(NSString *userOrPassword) {
	return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)userOrPassword, NULL, CFSTR(":@/?"), kCFStringEncodingUTF8));
}

static NSString *escapeString(NSString *string) {
	return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, NULL, kCFStringEncodingUTF8));
}

static NSString *unescapeString(NSString *string) {
	return CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)string, CFSTR(""), kCFStringEncodingUTF8));
}

@interface NSURL (Additions_Internal)

+ (NSArray *)_packageExtensions;

@end

@implementation NSURL (Additions)

+ (NSURL *)URLWithScheme:(NSString *)scheme user:(NSString *)user host:(NSString *)host port:(UInt16)port path:(NSString *)path {
	NSMutableString *string = [NSMutableString string];
	
	if (scheme.length == 0 || host.length == 0) return nil;
	
	[string appendFormat:@"%@://", scheme];
	
	if (user.length > 0) {
		user = escapeUserOrPassword(user);
		[string appendFormat:@"%@@", user];
	}
	
	[string appendString:host];
	
	if (port != 0) [string appendFormat:@":%i", port];
	
	if (path.length > 0) {
		if ([path characterAtIndex:0] != '/') [string appendString:@"/"];
		[string appendString:escapeString(path)];
	}
	
	return [[[self class] URLWithString:string] standardizedURL];
}

+ (NSURL *)applicationDocumentsDirectory {
  return [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
}

+ (NSURL *)applicationLibraryDirectory {
  return [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0]];
}

+ (NSURL *)temporaryDirectory {
  NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"actmpdir.XXXXXX"];
  const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	unsigned templateLength = strlen(tempDirectoryTemplateCString);
  char *tempDirectoryNameCString = (char *)malloc(templateLength + 1);
  strlcpy(tempDirectoryNameCString, tempDirectoryTemplateCString, templateLength + 1);
  
  char *result = mkdtemp(tempDirectoryNameCString);
  if (!result) {
    // handle directory creation failure
		NSAssert(NO, @"Failed to create temporary directory.");
		free(tempDirectoryNameCString);
		return nil;
  }
  
  NSString *tempDirectoryPath = [NSFileManager.defaultManager stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
  free(tempDirectoryNameCString);
  
  return [NSURL fileURLWithPath:tempDirectoryPath isDirectory:YES];
}

+ (NSURL *)temporaryFileURL {
  NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"actmpfile.XXXXXX"];
  const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
	unsigned templateLength = strlen(tempFileTemplateCString);
  char *tempFileNameCString = (char *)malloc(templateLength + 1);
  strlcpy(tempFileNameCString, tempFileTemplateCString, templateLength + 1);
  int fileDescriptor = mkstemp(tempFileNameCString);
  
  if (fileDescriptor == -1) {
    // handle file creation failure
		NSAssert(NO, @"Failed to create temporary file.");
		free(tempFileNameCString);
		return nil;
  }
  
  // This is the file name if you need to access the file by name, otherwise you can remove
  // this line.
  NSString *tempFileName = [NSFileManager.defaultManager stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
  
  free(tempFileNameCString);
  
  return [NSURL fileURLWithPath:tempFileName isDirectory:NO];
}

- (BOOL)isSubdirectoryDescendantOfDirectoryAtURL:(NSURL *)directoryURL {
  if (![self.absoluteString hasPrefix:directoryURL.absoluteString]) {
    return NO;
  }
  return self.pathComponents.count != directoryURL.pathComponents.count + 1;
}

- (BOOL)isHidden {
  return [self.lastPathComponent characterAtIndex:0] == L'.';
}

- (BOOL)isHiddenDescendant {
  return !([self.absoluteString.stringByDeletingLastPathComponent rangeOfString:@"/."].location == NSNotFound);
}

- (BOOL)isPackage {
  for (NSString *packageExtension in [self.class _packageExtensions]) {
    if ([self.pathExtension isEqualToString:packageExtension]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isPackageDescendant {
  NSString *absoluteString = self.absoluteString;
  if ([absoluteString characterAtIndex:[absoluteString length] - 1] == L'/') {
    absoluteString = [absoluteString substringToIndex:[absoluteString length] - 1];
  }
  for (NSString *packageExtension in [self.class _packageExtensions]) {
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
    return isDirectory.boolValue;
  }
  // Backup by looking with the defaul file manager
  BOOL isDirectoryBool = NO;
  [NSFileManager.defaultManager fileExistsAtPath:self.path isDirectory:&isDirectoryBool];
  return isDirectoryBool;
}

- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number {
  return [self.URLByDeletingLastPathComponent URLByAppendingPathComponent:[self.lastPathComponent stringByAddingDuplicateNumber:number]];
}

- (NSString *)pathRelativeToURL:(NSURL *)url {
	if (self.path.length <= url.path.length || ![self.path hasPrefix:url.path]) return @"";
	return [self.path substringFromIndex:url.path.length + 1];
}

- (NSString *)prettyPath {
  return self.path.prettyPath;
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
