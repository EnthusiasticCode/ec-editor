//
//  DocSetDownloadManager.h
//  DocSets
//
//  Created by Ole Zorn on 22.01.12.
//  Copyright (c) 2012 omz:software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DocSetDownloadManagerAvailableDocSetsChangedNotification	@"DocSetDownloadManagerAvailableDocSetsChangedNotification"
#define DocSetDownloadManagerStartedDownloadNotification			@"DocSetDownloadManagerStartedDownloadNotification"
#define DocSetDownloadManagerUpdatedDocSetsNotification				@"DocSetDownloadManagerUpdatedDocSetsNotification"
#define DocSetDownloadFinishedNotification							@"DocSetDownloadFinishedNotification"

@class DocSet, DocSetDownload;

@interface DocSetDownloadManager : NSObject {

	NSArray *_downloadedDocSets;
	NSSet *_downloadedDocSetNames;
	
	NSArray *_availableDownloads;
	NSMutableDictionary *_downloadsByURL;
	DocSetDownload *_currentDownload;
	NSMutableArray *_downloadQueue;
	
	NSDate *_lastUpdated;
	BOOL _updatingAvailableDocSetsFromWeb;
}

@property (nonatomic, strong) NSArray *downloadedDocSets;
@property (nonatomic, strong) NSSet *downloadedDocSetNames;
@property (nonatomic, strong) NSArray *availableDownloads;
@property (nonatomic, strong) DocSetDownload *currentDownload;
@property (nonatomic, strong) NSDate *lastUpdated;

+ (id)sharedDownloadManager;
- (void)reloadAvailableDocSets;
- (void)updateAvailableDocSetsFromWeb;
- (void)downloadDocSetAtURL:(NSString *)URL;
- (void)deleteDocSet:(DocSet *)docSetToDelete;
- (DocSetDownload *)downloadForURL:(NSString *)URL;
- (void)stopDownload:(DocSetDownload *)download;
- (DocSet *)downloadedDocSetWithName:(NSString *)docSetName;

@end


typedef enum DocSetDownloadStatus {
	DocSetDownloadStatusWaiting = 0,
	DocSetDownloadStatusDownloading,
	DocSetDownloadStatusExtracting,
	DocSetDownloadStatusFinished
} DocSetDownloadStatus;

@interface DocSetDownload : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {

	UIBackgroundTaskIdentifier _backgroundTask;
	NSURL *_URL;
	NSURLConnection *_connection;
	NSFileHandle *_fileHandle;
	NSString *_downloadTargetPath;
	NSString *_extractedPath;
	
	DocSetDownloadStatus _status;
	float _progress;
    BOOL _shouldCancelExtracting;
	NSUInteger bytesDownloaded;
	NSInteger downloadSize;
}

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSURLConnection *connection;
@property (atomic, strong) NSURL *downloadTargetURL;
@property (nonatomic, strong) NSURL *extractedURL;
@property (nonatomic, assign) DocSetDownloadStatus status;
@property (nonatomic, assign) float progress;
@property (atomic, assign) BOOL shouldCancelExtracting; // must be atomic
@property (atomic, readonly) NSUInteger bytesDownloaded;
@property (atomic, readonly) NSInteger downloadSize;

- (id)initWithURL:(NSURL *)URL;
- (void)start;
- (void)cancel;
- (void)fail;

@end


@interface NSURL (DocSet)

/// Returns the downloaded and available docset from the URL host by name
- (DocSet *)docSet;

/// From a file:// URL, return a docset URL if possible.
- (NSURL *)docSetURLByRetractingFileURL;

/// Returns a docset-file URL to the resource of the docset + anchor
- (NSURL *)docSetFileURLByResolvingDocSet;



@end