//
//  SubsonicRequestManager.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "SubsonicRequestManager.h"

@interface SubsonicRequestManager()

@property(strong, nonatomic) NSString *cacheDirectory;

@end

@implementation SubsonicRequestManager

@synthesize server, username, password, cacheDirectory;

+ (id) sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
        ((SubsonicRequestManager *)_sharedObject).cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        //NSLog(@"%@",((SubsonicRequestManager *)_sharedObject).cacheDirectory);
    });
    return _sharedObject;
}

- (void) getArtistSectionsForMusicFolder:(NSInteger) musicFolderID delegate:(NSObject <SubsonicArtistSectionsRequestDelegate> *) delegate;
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *urlString = [NSString stringWithFormat:@"http://%@/rest/getIndexes.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&musicFolderId=%d", server, username, password, musicFolderID];
        NSData *artistSectionsResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        NSDictionary *subsonicResponse = [[JSONDecoder decoder] objectWithData:artistSectionsResponse];
        NSMutableDictionary *sections = [[NSMutableDictionary alloc] init];
        for (NSDictionary *index in subsonicResponse[@"subsonic-response"][@"indexes"][@"index"]) {
            if ([index[@"artist"] isKindOfClass:[NSArray class]]) {
                sections[index[@"name"]] = [index[@"artist"] mutableCopy];
            } else {
                sections[index[@"name"]] = [@[index[@"artist"]] mutableCopy];
            }
        }
        for (NSDictionary *child in subsonicResponse[@"subsonic-response"][@"indexes"][@"child"]) {
            unichar firstLetter = [((NSString *)child[@"title"])characterAtIndex:0];
            if (sections[[NSString stringWithCharacters:&firstLetter length:1]]) {
                NSMutableDictionary *object = [child mutableCopy];
                object[@"name"] = object[@"title"];
                [sections[[NSString stringWithCharacters:&firstLetter length:1]] addObject:object];
            }
        }
        [delegate performSelectorOnMainThread:@selector(artistSectionsRequestDidSucceedWithSections:) withObject:sections waitUntilDone:NO];
    });
}

- (void) getAlbumsForArtistID:(NSString *)artistID delegate:(NSObject<SubsonicArtistAlbumsRequestDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *urlString = [NSString stringWithFormat:@"http://%@/rest/getMusicDirectory.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&id=%@", server, username, password, artistID];
        NSData *artistAlbumResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        NSDictionary *subsonicResponse = [[JSONDecoder decoder] objectWithData:artistAlbumResponse];
        NSObject *albumsObject = subsonicResponse[@"subsonic-response"][@"directory"][@"child"];
        if ([albumsObject isKindOfClass:[NSArray class]]) {
            if ([((NSArray*)albumsObject)[0][@"isDir"] intValue])
                [delegate performSelectorOnMainThread:@selector(artistAlbumsRequestDidSucceedWithAlbums:) withObject:albumsObject waitUntilDone:NO];
            else {
                [delegate performSelectorOnMainThread:@selector(artistAlbumsRequestDidSucceedWithAlbums:) withObject:@[subsonicResponse[@"subsonic-response"][@"directory"]] waitUntilDone:NO];
            }
        } else {
            [delegate performSelectorOnMainThread:@selector(artistAlbumsRequestDidSucceedWithAlbums:) withObject:@[albumsObject] waitUntilDone:NO];
        }
    });
}

- (void) getSongsForAlbumID:(NSString *)albumID delegate:(NSObject<SubsonicAlbumSongsRequestDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *urlString = [NSString stringWithFormat:@"http://%@/rest/getMusicDirectory.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&id=%@", server, username, password, albumID];
        NSData *albumSongsResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        NSDictionary *subsonicResponse = [[JSONDecoder decoder] objectWithData:albumSongsResponse];
        NSObject *albumSongs = subsonicResponse[@"subsonic-response"][@"directory"][@"child"];
        if ([albumSongs isKindOfClass:[NSArray class]]) {
            [delegate performSelectorOnMainThread:@selector(albumSongsRequestDidSucceedWithSongs:) withObject:albumSongs waitUntilDone:NO];
        } else {
            [delegate performSelectorOnMainThread:@selector(albumSongsRequestDidSucceedWithSongs:) withObject:@[albumSongs] waitUntilDone:NO];
        }
    });
}

- (void) getSongsForArtistID:(NSString *)artistID delegate:(NSObject<SubsonicArtistSongsRequestDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *albumsURLString = [NSString stringWithFormat:@"http://%@/rest/getMusicDirectory.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&id=%@", server, username, password, artistID];
        NSData *artistAlbumsResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:albumsURLString]];
        NSDictionary *subsonicResponse = [[JSONDecoder decoder] objectWithData:artistAlbumsResponse];
        NSObject *albumsObject = subsonicResponse[@"subsonic-response"][@"directory"][@"child"];
        NSArray *albums;
        NSMutableDictionary *songs = [[NSMutableDictionary alloc] init];
        if ([albumsObject isKindOfClass:[NSArray class]]) {
            if ([((NSArray*)albumsObject)[0][@"isDir"] intValue]) {
                albums = (NSArray*)albumsObject;
            } else {
                NSDictionary *album = subsonicResponse[@"subsonic-response"][@"directory"];
                songs[album[@"name"]] = album[@"child"];
                [delegate performSelectorOnMainThread:@selector(artistSongsRequestDidSucceedWithSongs:) withObject:songs waitUntilDone:NO];
            }
        } else {
            //NSLog(@"sr: %@",subsonicResponse);
            if ([((NSDictionary*)albumsObject)[@"isDir"] intValue]) {
                albums = @[albumsObject];
            } else {
                NSDictionary *album = subsonicResponse[@"subsonic-response"][@"directory"];
                songs[album[@"name"]] = album[@"child"];
                if (![album[@"child"] isKindOfClass:[NSArray class]])
                    songs[album[@"name"]] = @[album[@"child"]];
                [delegate performSelectorOnMainThread:@selector(artistSongsRequestDidSucceedWithSongs:) withObject:songs waitUntilDone:NO];
            }
            
        }
        for (NSDictionary *album in albums) {
            NSString *songsURLString = [NSString stringWithFormat:@"http://%@/rest/getMusicDirectory.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&id=%@", server, username, password, album[@"id"]];
            NSData *albumSongsResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:songsURLString]];
            NSDictionary *subsonicResponse2 = [[JSONDecoder decoder] objectWithData:albumSongsResponse];

            NSString *sectionIndex = album[@"title"];
            if (!album[@"title"]) sectionIndex = album[@"name"];
            //NSLog(@"album: %@",album);
            NSObject *albumSongs = subsonicResponse2[@"subsonic-response"][@"directory"][@"child"];
           //if (subsonicResponse2[@"child"]) albumSongs = subsonicResponse2[@"child"];
            //NSLog(@"sr2 %@",subsonicResponse2);
            if ([albumSongs isKindOfClass:[NSArray class]]) {
                songs[album[@"title"]] = (NSArray *)albumSongs;
            } else {
                songs[sectionIndex] = @[albumSongs];
            }
        }
        [delegate performSelectorOnMainThread:@selector(artistSongsRequestDidSucceedWithSongs:) withObject:songs waitUntilDone:NO];
    });
}

- (void) getCoverArtForID:(NSString *)coverID delegate:(NSObject<SubsonicAlbumCoverRequestDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //NSLog(@"%@",cacheDirectory);
        NSString* cachePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",coverID]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            NSString *coverURLString = [NSString stringWithFormat:@"http://%@/rest/getCoverArt.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld&id=%@&size=500", server, username, password, coverID];
            NSData *coverResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:coverURLString]];
            [coverResponse writeToFile:cachePath atomically:YES];
            [delegate performSelectorOnMainThread:@selector(albumCoverRequestDidSucceedWithImage:) withObject:[UIImage imageWithData:coverResponse] waitUntilDone:NO];
        } else {
            NSData *coverData = [NSData dataWithContentsOfFile:cachePath];
            [delegate performSelectorOnMainThread:@selector(albumCoverRequestDidSucceedWithImage:) withObject:[UIImage imageWithData:coverData] waitUntilDone:NO];
        }
    });
}

- (void) pingServerWithDelegate:(NSObject <SubsonicPingRequestDelegate> *) delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *pingURLString = [NSString stringWithFormat:@"http://%@/rest/ping.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld", server, username, password];
        NSError *error;
        NSData *pingResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:pingURLString] options:NSDataReadingUncached error:&error];
        if (error) {
            [delegate performSelectorOnMainThread:@selector(pingRequestDidFailWithError:) withObject:@(ServerErrorBadConnection) waitUntilDone:NO];
        } else {
            NSDictionary * subsonicResponse = [[JSONDecoder decoder] objectWithData:pingResponse];
            //NSLog(@"%@",subsonicResponse);
            if ([subsonicResponse[@"subsonic-response"][@"status"] isEqualToString:@"ok"]) {
                [delegate performSelectorOnMainThread:@selector(pingRequestDidSucceed) withObject:nil waitUntilDone:NO];
            } else {
                SubsonicServerError serverError;
                switch ([subsonicResponse[@"subsonic-response"][@"error"][@"code"] intValue]) {
                    case 0:
                        serverError = ServerErrorUnknownError;
                        break;
                    case 10:
                        serverError = ServerErrorMissingParameter;
                        break;
                    case 40:
                        serverError = ServerErrorBadCredentials;
                        break;
                    case 50:
                        serverError = ServerErrorUnauthorizedOperation;
                        break;
                    case 60:
                        serverError = ServerErrorNoLicense;
                        break;
                    case 70:
                        serverError = ServerErrorDataNotFound;
                        break;
                }
                dispatch_async( dispatch_get_main_queue(), ^{
                    [delegate pingRequestDidFailWithError:serverError];
                });
            }
        }
    });
}

- (void) resetSessionWithDelegate:(NSObject<SubsonicResetSessionDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *pingURLString = [NSString stringWithFormat:@"http://%@/rest/ping.view", server];
        NSData *pingResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:pingURLString]];
        (void)pingResponse;
        dispatch_async( dispatch_get_main_queue(), ^{
            [delegate resetSessionDidFinish];
        });
    });
}

- (void) requestMusicFoldersWithDelegate:(NSObject<SubsonicMusicFoldersRequestDelegate> *)delegate {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        //NSLog(@"hello");
        NSString *folderURLString = [NSString stringWithFormat:@"http://%@/rest/getMusicFolders.view?f=json&u=%@&p=%@&v=1.7.0&c=helloworld",server,username,password];
        NSData *folderResponse = [NSData dataWithContentsOfURL:[NSURL URLWithString:folderURLString]];
        NSDictionary *subsonicResponse = [[JSONDecoder decoder] objectWithData:folderResponse];
        //NSLog(@"%@",subsonicResponse);
        dispatch_async( dispatch_get_main_queue(), ^{
            [delegate musicFolderRequestDidSucceedWithFolders:subsonicResponse[@"subsonic-response"][@"musicFolders"][@"musicFolder"]];
        });
    });
}


@end
