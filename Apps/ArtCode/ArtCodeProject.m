//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProject.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"
#import "NSString+Utilities.h"

#import "ArtCodeLocation.h"
#import "ArtCodeProjectSet.h"

#import "FileSystemItem.h"


@interface ArtCodeProjectBookmark ()

+ (ArtCodeProjectBookmark *)bookmarkWithFileURL:(NSURL *)fileURL lineNumber:(NSUInteger)lineNumber;

@end

#pragma mark -

@implementation ArtCodeProject

#pragma mark - KVO overrides

+ (NSSet *)keyPathsForValuesAffectingFileURL {
  return [NSSet setWithObjects:@"name", @"projectSet.fileURL", nil];
}

+ (NSSet *)keyPathsForValuesAffectingLabelColor {
  return [NSSet setWithObject:@"labelColorString"];
}

#pragma mark - Public Methods

- (NSURL *)fileURL {
  return [[[self projectSet] fileURL] URLByAppendingPathComponent:[self name]];
}

- (UIColor *)labelColor {
  return [UIColor colorWithHexString:[self labelColorString]];
}

- (void)setLabelColor:(UIColor *)labelColor {
  [self setLabelColorString:[labelColor hexString]];
}

- (void)bookmarksWithResultHandler:(void (^)(NSArray *))resultHandler {
  // TODO: port to rac_fs
  resultHandler(@[]);
}

#pragma mark - Project-wide operations

- (void)duplicateWithCompletionHandler:(void (^)(ArtCodeProject *))completionHandler {
  [self _duplicateWithDuplicationNumber:1 completionHandler:completionHandler];
}

/// Recursive method to create a duplicated project
- (void)_duplicateWithDuplicationNumber:(NSUInteger)duplicationNumber completionHandler:(void (^)(ArtCodeProject *))completionHandler {
  @weakify(self);
  [self.projectSet addNewProjectWithName:[self.name stringByAppendingFormat:@" (%u)", duplicationNumber] labelColor:self.labelColor completionHandler:^(ArtCodeProject *project) {
    @strongify(self);
    if (project) {
      // The project has been successfuly created, copying files
			[[[RACSignal zip:@[ [[FileSystemDirectory directoryWithURL:self.fileURL] flattenMap:^(FileSystemDirectory *x) {
        return [[x children] take:1];
      }], [FileSystemDirectory directoryWithURL:project.fileURL] ] reduce:^(NSArray *x1, FileSystemDirectory *x2) {
        return [RACSignal zip:[[x1 rac_sequence] map:^(FileSystemItem *y) {
          return [y copyTo:x2];
        }]];
      }] flatten] subscribeCompleted:^{
        if (completionHandler) {
          completionHandler(project);
        }
      }];
    } else {
      [self _duplicateWithDuplicationNumber:duplicationNumber + 1 completionHandler:completionHandler];
    }
  }];
}

@end

#pragma mark -

@implementation ArtCodeProjectBookmark

@synthesize fileURL = _fileURL, lineNumber = _lineNumber, name = _name;

+ (ArtCodeProjectBookmark *)bookmarkWithFileURL:(NSURL *)fileURL lineNumber:(NSUInteger)lineNumber {
  ASSERT(fileURL);
  ArtCodeProjectBookmark *bookmark = [[self alloc] init];
  bookmark->_fileURL = fileURL;
  bookmark->_lineNumber = lineNumber;
  bookmark->_name = [NSString stringWithFormat:@"%@: %d", fileURL.lastPathComponent, lineNumber];
  return bookmark;
}

@end