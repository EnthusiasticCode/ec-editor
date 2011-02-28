//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECCodeIndexer.h"
#import "ECCodeIndexingFile.h"
#import <ECAdditions/NSURL+ECAdditions.h>
#import <MobileCoreServices/MobileCoreServices.h>
// TODO: plugins are hardcoded for now
#import "ECClangCodeIndexer.h"

@interface ECCodeIndexer ()
@property (nonatomic, copy) NSDictionary *pluginsByLanguage;
@property (nonatomic, copy) NSDictionary *pluginsByUTI;
@property (nonatomic, copy) NSSet *handledLanguages;
@property (nonatomic, copy) NSSet *handledUTIs;
@property (nonatomic, retain) NSMutableDictionary *files;
- (id<ECCodeIndexer>)defaultPluginForFile:(NSURL *)fileURL;
- (id<ECCodeIndexer>)pluginForFile:(ECCodeIndexingFile *)file;
- (id<ECCodeIndexer>)pluginforLanguage:(NSString *)language;
@end


@implementation ECCodeIndexer

@synthesize pluginsByLanguage = _pluginsByLanguage;
@synthesize pluginsByUTI = _pluginsByUTI;
@synthesize handledLanguages = _handledLanguages;
@synthesize handledUTIs = _handledUTIs;
@synthesize files = _files;

- (NSSet *)handledFiles
{
    return [NSSet setWithArray:[self.files allKeys]];
}

- (void)dealloc
{
    self.pluginsByLanguage = nil;
    self.pluginsByUTI = nil;
    self.handledLanguages = nil;
    self.handledUTIs = nil;
    self.files = nil;
    [super dealloc];
}

- (id)init
{
    // TODO: implement some priority system for subclass loading
    self = [super init];
    if (!self)
        return nil;
    NSMutableDictionary *pluginsByLanguage = [NSMutableDictionary dictionary];
    NSMutableDictionary *pluginsByUTI = [NSMutableDictionary dictionary];
    NSMutableSet *handledLanguages = [NSMutableSet set];
    NSMutableSet *handledUTIs = [NSMutableSet set];
    // TODO: plugin architecture or something like that
    NSArray *pluginClasses = [NSArray arrayWithObjects:[ECClangCodeIndexer class], nil];
    id<ECCodeIndexer> plugin;
    for (Class pluginClass in pluginClasses)
    {
        if (![pluginClass conformsToProtocol:@protocol(ECCodeIndexer)])
            continue;
        plugin = [[pluginClass alloc] init];
        for (NSString *language in [plugin handledLanguages])
        {
            if ([handledLanguages containsObject:language])
                continue;
            [pluginsByLanguage setObject:plugin forKey:language];
            [handledLanguages addObject:language];
        }
        for (NSString *UTI in [plugin handledUTIs])
        {
            if ([handledUTIs containsObject:UTI])
                continue;
            [pluginsByUTI setObject:plugin forKey:UTI];
            [handledUTIs addObject:UTI];
        }
    }
    self.pluginsByLanguage = pluginsByLanguage;
    self.pluginsByUTI = pluginsByUTI;
    self.handledLanguages = handledLanguages;
    self.handledUTIs = handledUTIs;
    return self;
}

- (id<ECCodeIndexer>)defaultPluginForFile:(NSURL *)fileURL
{
    NSString *extension = [fileURL pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
    id<ECCodeIndexer> plugin = [self.pluginsByUTI objectForKey:(NSString *)UTI];
    CFRelease(UTI);
    return plugin;
}

- (id<ECCodeIndexer>)pluginForFile:(ECCodeIndexingFile *)file
{
    if (file.language)
        return [self pluginforLanguage:file.language];
    return [self defaultPluginForFile:file.URL];
}

- (id<ECCodeIndexer>)pluginforLanguage:(NSString *)language
{
    return [self.pluginsByLanguage objectForKey:language];
}

- (void)addFilesObject:(NSURL *)fileURL
{
    if (![fileURL isFileURLAndExists])
        return;
    [self.files setObject:[ECCodeIndexingFile fileWithURL:fileURL language:nil buffer:nil]  forKey:fileURL];
    [[self defaultPluginForFile:fileURL] addFilesObject:fileURL];
}

- (void)removeFilesObject:(NSURL *)fileURL
{
    [[self pluginForFile:[self.files objectForKey:fileURL]] removeFilesObject:fileURL];
    [self.files removeObjectForKey:fileURL];
}

- (void)setLanguage:(NSString *)language forFile:(NSURL *)fileURL
{
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    if (!file || [file.language isEqualToString:language])
        return;
    [[self pluginForFile:file] removeFilesObject:fileURL];
    file.language = language;
    [[self pluginForFile:file] addFilesObject:fileURL];
}

- (void)setBuffer:(NSString *)buffer forFile:(NSURL *)fileURL
{
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    if (!file || [file.buffer isEqualToString:buffer])
        return;
    file.buffer = buffer;
    [[self pluginForFile:file] setBuffer:buffer forFile:fileURL];
}

- (NSArray *)completionsForFile:(NSURL *)fileURL withSelection:(NSRange)selection
{
    return [[self pluginForFile:[self.files objectForKey:fileURL]] completionsForFile:fileURL withSelection:selection];
}

- (NSArray *)diagnosticsForFile:(NSURL *)fileURL
{
    return [[self pluginForFile:[self.files objectForKey:fileURL]] diagnosticsForFile:fileURL];
}

- (NSArray *)fixItsForFile:(NSURL *)fileURL
{
    return [[self pluginForFile:[self.files objectForKey:fileURL]] fixItsForFile:fileURL];
}

- (NSArray *)tokensForFile:(NSURL *)fileURL inRange:(NSRange)range
{
    return [[self pluginForFile:[self.files objectForKey:fileURL]] tokensForFile:fileURL inRange:range];
}

- (NSArray *)tokensForFile:(NSURL *)fileURL
{
    return [[self pluginForFile:[self.files objectForKey:fileURL]] tokensForFile:fileURL];
}

@end
