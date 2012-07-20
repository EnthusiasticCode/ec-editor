//
//  DocSetDownloadManager.m
//  DocSets
//
//  Created by Ole Zorn on 22.01.12.
//  Copyright (c) 2012 omz:software. All rights reserved.
//

#import "DocSetDownloadManager.h"
#import "DocSet.h"
//#import "xar.h"
#include <sys/xattr.h>
#import "NSURL+Utilities.h"
#import "ArchiveUtilities.h"

static NSString * const docSetContentsPath = @"Contents/Resources/Documents";

@interface DocSetDownloadManager ()

- (void)startNextDownload;
- (void)reloadDownloadedDocSets;
- (void)downloadFinished:(DocSetDownload *)download;
- (void)downloadFailed:(DocSetDownload *)download;

@end


@implementation DocSetDownloadManager

@synthesize downloadedDocSets=_downloadedDocSets, downloadedDocSetNames=_downloadedDocSetNames, availableDownloads=_availableDownloads, currentDownload=_currentDownload, lastUpdated=_lastUpdated;

- (id)init
{
	self = [super init];
	if (self) {
		[self reloadAvailableDocSets];
		_downloadsByURL = [NSMutableDictionary new];
		_downloadQueue = [NSMutableArray new];
		[self reloadDownloadedDocSets];
	}
	return self;
}

- (void)reloadAvailableDocSets
{
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *cachedAvailableDownloadsPath = [cachesPath stringByAppendingPathComponent:@"AvailableDocSets.plist"];
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (![fm fileExistsAtPath:cachedAvailableDownloadsPath]) {
		NSString *bundledAvailableDocSetsPlistPath = [[NSBundle mainBundle] pathForResource:@"AvailableDocSets" ofType:@"plist"];
		[fm copyItemAtPath:bundledAvailableDocSetsPlistPath toPath:cachedAvailableDownloadsPath error:NULL];
	}
	self.lastUpdated = [[fm attributesOfItemAtPath:cachedAvailableDownloadsPath error:NULL] fileModificationDate];
	_availableDownloads = [(NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:cachedAvailableDownloadsPath] objectForKey:@"DocSets"];
}

- (void)updateAvailableDocSetsFromWeb
{
	if (_updatingAvailableDocSetsFromWeb) return;
	_updatingAvailableDocSetsFromWeb = YES;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		NSURL *availableDocSetsURL = [NSURL URLWithString:@"https://raw.github.com/omz/DocSets-for-iOS/master/Resources/AvailableDocSets.plist"];
		NSHTTPURLResponse *response = nil;
		NSData *updatedDocSetsData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:availableDocSetsURL] returningResponse:&response error:NULL];
		if (response.statusCode == 200) {
			NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:updatedDocSetsData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if (plist && [plist objectForKey:@"DocSets"]) {
				NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
				NSString *cachedAvailableDownloadsPath = [cachesPath stringByAppendingPathComponent:@"AvailableDocSets.plist"];
				[updatedDocSetsData writeToFile:cachedAvailableDownloadsPath atomically:YES];
			} else {
				//Downloaded file is somehow not a valid plist...
			}	
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			_updatingAvailableDocSetsFromWeb = NO;
			[self reloadAvailableDocSets];
			[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadManagerAvailableDocSetsChangedNotification object:self];
		});
	});
}

- (void)reloadDownloadedDocSets
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSArray *documents = [fm contentsOfDirectoryAtPath:docPath error:NULL];
	NSMutableArray *loadedSets = [NSMutableArray array];
	for (NSString *path in documents) {
		if ([[[path pathExtension] lowercaseString] isEqual:@"docset"]) {
			NSString *fullPath = [docPath stringByAppendingPathComponent:path];
			u_int8_t b = 1;
			setxattr([fullPath fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
			DocSet *docSet = [[DocSet alloc] initWithPath:fullPath];
			if (docSet) [loadedSets addObject:docSet];
		}
	}
	self.downloadedDocSets = [NSArray arrayWithArray:loadedSets];
	self.downloadedDocSetNames = [NSSet setWithArray:documents];
	[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadManagerUpdatedDocSetsNotification object:self];
}

+ (id)sharedDownloadManager
{
	static id sharedDownloadManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDownloadManager = [[self alloc] init];
	});
	return sharedDownloadManager;
}

- (DocSetDownload *)downloadForURL:(NSString *)URL
{
	return [_downloadsByURL objectForKey:URL];
}

- (void)stopDownload:(DocSetDownload *)download
{
	if (download.status == DocSetDownloadStatusWaiting) {
		[_downloadQueue removeObject:download];
		[_downloadsByURL removeObjectForKey:[download.URL absoluteString]];
		[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadFinishedNotification object:download];
	} else if (download.status == DocSetDownloadStatusDownloading) {
		[download cancel];
		self.currentDownload = nil;
		[_downloadsByURL removeObjectForKey:[download.URL absoluteString]];
		[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadFinishedNotification object:download];
		[self startNextDownload];
	} else if (download.status == DocSetDownloadStatusExtracting) {
		download.shouldCancelExtracting = YES;
	}
}

- (void)downloadDocSetAtURL:(NSString *)URL
{
	if ([_downloadsByURL objectForKey:URL]) {
		//already downloading
		return;
	}
	
	DocSetDownload *download = [[DocSetDownload alloc] initWithURL:[NSURL URLWithString:URL]];
	[_downloadQueue addObject:download];
	[_downloadsByURL setObject:download forKey:URL];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadManagerStartedDownloadNotification object:self];
	
	[self startNextDownload];
}

- (void)deleteDocSet:(DocSet *)docSetToDelete
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DocSetWillBeDeletedNotification object:docSetToDelete userInfo:nil];
	[[NSFileManager defaultManager] removeItemAtPath:docSetToDelete.path error:NULL];
	[self reloadDownloadedDocSets];
}

- (DocSet *)downloadedDocSetWithName:(NSString *)docSetName
{
	for (DocSet *docSet in _downloadedDocSets) {
		if ([[docSet.path lastPathComponent] isEqualToString:docSetName]) {
			return docSet;
		}
	}
	return nil;
}

- (void)startNextDownload
{
	if ([_downloadQueue count] == 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		return;
	}
	if (self.currentDownload != nil) return;
	
	self.currentDownload = [_downloadQueue objectAtIndex:0];
	[_downloadQueue removeObjectAtIndex:0];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[self.currentDownload start];
}

- (void)downloadFinished:(DocSetDownload *)download
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadFinishedNotification object:download];
	
	NSArray *extractedItems = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:download.extractedURL includingPropertiesForKeys:nil options:0 error:NULL];
	for (NSString *file in extractedItems) {
		if ([[[file pathExtension] lowercaseString] isEqualToString:@"docset"]) {
			NSURL *fullURL = [download.extractedURL URLByAppendingPathComponent:file];
			NSURL *targetURL = [[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:file];
			[[NSFileManager defaultManager] moveItemAtURL:fullURL toURL:targetURL error:NULL];
		}
	}
  
  // TODO bezel alert here
	
	[self reloadDownloadedDocSets];
	
	[_downloadsByURL removeObjectForKey:[download.URL absoluteString]];	
	self.currentDownload = nil;
	[self startNextDownload];
}

- (void)downloadFailed:(DocSetDownload *)download
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DocSetDownloadFinishedNotification object:download];
	[_downloadsByURL removeObjectForKey:[download.URL absoluteString]];	
	self.currentDownload = nil;
	[self startNextDownload];
	
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Failed", nil) 
								 message:NSLocalizedString(@"An error occured while trying to download the DocSet.", nil) 
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK", nil) 
					   otherButtonTitles:nil] show];
}

@end



@implementation DocSetDownload

@synthesize connection=_connection, URL=_URL, fileHandle=_fileHandle, downloadTargetURL=_downloadTargetURL, extractedURL=_extractedURL, progress=_progress, status=_status, shouldCancelExtracting = _shouldCancelExtracting;
@synthesize downloadSize, bytesDownloaded;

- (id)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self) {
		_URL = URL;
		self.status = DocSetDownloadStatusWaiting;
	}
	return self;
}

- (void)start
{
	if (self.status != DocSetDownloadStatusWaiting) {
		return;
	}
	
	_backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
	
	self.status = DocSetDownloadStatusDownloading;
	
	self.downloadTargetURL = [[NSURL temporaryDirectory] URLByAppendingPathComponent:@"docdownload.zip"];
	[@"" writeToURL:self.downloadTargetURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	self.fileHandle = [NSFileHandle fileHandleForWritingToURL:self.downloadTargetURL error:NULL];
	
	bytesDownloaded = 0;
	self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.URL] delegate:self];
}

- (void)cancel
{
	if (self.status == DocSetDownloadStatusDownloading) {
		[self.connection cancel];
		self.status = DocSetDownloadStatusFinished;
		if (_backgroundTask != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	downloadSize = [[headers objectForKey:@"Content-Length"] integerValue];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	bytesDownloaded += [data length];
	if (downloadSize != 0) {
		self.progress = (float)bytesDownloaded / (float)downloadSize;
		//NSLog(@"Download progress: %f", self.progress);
	}
	[self.fileHandle writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self.fileHandle closeFile];
	self.fileHandle = nil;
	
	self.status = DocSetDownloadStatusExtracting;
	self.progress = 0.0;
	
  NSURL *extractionTargetURL = [[self.downloadTargetURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"docset_extract"];
  self.extractedURL = extractionTargetURL;
  
  [ArchiveUtilities coordinatedExtractionOfArchiveAtURL:self.downloadTargetURL toURL:extractionTargetURL completionHandler:^(NSError *error) {
    self.status = DocSetDownloadStatusFinished;
    [[DocSetDownloadManager sharedDownloadManager] downloadFinished:self];
    
    if (_backgroundTask != UIBackgroundTaskInvalid) {
      [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
    }
  }];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self fail];
}

- (void)fail
{
	[[DocSetDownloadManager sharedDownloadManager] downloadFailed:self];
	if (_backgroundTask != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
	}
}

@end

@implementation NSURL (DocSet)

- (DocSet *)docSet {
  NSString *docSetName = nil;
  if (self.isFileURL) {
    NSString *path = [self.path substringFromIndex:[NSURL applicationDocumentsDirectory].path.length];
    NSRange pathContentsRange = [path rangeOfString:docSetContentsPath];
    if (pathContentsRange.location != NSNotFound) {
      docSetName = [path substringToIndex:pathContentsRange.location - 1];
    } else {
      // TODO get untill /
      docSetName = path;
    }
  } else {
    docSetName = [self.host stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  }
  for (DocSet *docSet in [[DocSetDownloadManager sharedDownloadManager] downloadedDocSets]) {
    if ([docSet.name isEqualToString:docSetName]) {
      return docSet;
    }
  }
  return nil;
}

- (NSURL *)docSetURLByRetractingFileURL {
  NSString *path = self.path;
  for (DocSet *docSet in [[DocSetDownloadManager sharedDownloadManager] downloadedDocSets]) {
    if ([path hasPrefix:docSet.path]) {
      if ([path rangeOfString:@"#"].location == NSNotFound) {
        path = self.absoluteString;
      }
      path = [path substringFromIndex:NSMaxRange([path rangeOfString:@"Contents/Resources/Documents"])];
      NSUInteger fragmentPosition = [path rangeOfString:@"#"].location;
      if (fragmentPosition != NSNotFound) {
        path = [NSString stringWithFormat:@"docset://%@%@", [[docSet.name stringByAppendingPathComponent:[path substringToIndex:fragmentPosition]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [path substringFromIndex:fragmentPosition]];
      } else {
        path = [NSString stringWithFormat:@"docset://%@", [docSet.name stringByAppendingPathComponent:path]];
      }
      return [NSURL URLWithString:path];
    }
  }
  return nil;
}

- (NSURL *)docSetFileURLByResolvingDocSet {
  DocSet *docSet = self.docSet;
  if (!docSet)
    return nil;
  NSString *URLString = [docSet.path stringByAppendingPathComponent:@"Contents/Resources/Documents"];
  if (self.path.length) {
    URLString = [[URLString stringByAppendingPathComponent:self.path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  } else {
    return nil;
  }
  if (self.fragment.length) {
    URLString = [URLString stringByAppendingFormat:@"#%@", self.fragment];
  }
  return [NSURL URLWithString:[NSString stringWithFormat:@"docset-file://%@", URLString]];
}

@end
