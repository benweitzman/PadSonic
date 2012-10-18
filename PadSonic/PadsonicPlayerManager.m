//
//  PadsonicPlayerManager.m
//  PadSonic
//
//  Created by Ben Weitzman on 10/18/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import "PadsonicPlayerManager.h"
#import "SVProgressHUD.h"

@implementation PadsonicPlayerManager

@synthesize currentPlaylist,currentPlaylistIdx,currentSong,currentSongIdx,mplayer,as,playlists;

+ (id) sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

- (id) init {
    self = [super init];
    if (self) {
        [[SubsonicRequestManager sharedInstance] getPlaylistsWithDelegate:self];
    }
    return self;
}

- (void) addNewPlaylistWithName:(NSString *)name {
    [playlists addObject:[@{@"entry":[[NSMutableArray alloc] init],@"name":name,@"temporary":@NO} mutableCopy]];
    [self writePlaylistsToFile];
}

- (void) writePlaylistsToFile {
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *playlistFile = [cacheDirectory stringByAppendingPathComponent:@"playlists.plist"];
    NSString *tempPlaylistFile = [cacheDirectory stringByAppendingPathComponent:@"tempPlaylist.plist"];
    [[playlists objectsAtIndexes:[playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
        return [obj[@"temporary"] isEqualToNumber:@NO];
    }]] writeToFile:playlistFile atomically:YES];
    [(NSMutableDictionary *)[playlists objectAtIndex:[playlists indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
        return [obj[@"temporary"] isEqualToNumber:@YES];
    }]] writeToFile:tempPlaylistFile atomically:YES];
}

- (void) syncPlaylists {
    [SVProgressHUD showWithStatus:@"Syncing Playlists" maskType:SVProgressHUDMaskTypeBlack];
    [[SubsonicRequestManager sharedInstance] syncPlaylists:
     [playlists objectsAtIndexes:
      [playlists indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL* stop) {
         return [obj[@"temporary"] isEqualToNumber:@NO];
     }]] withDelegate:self];
}

- (void) playSongWithIndex:(NSInteger)songIndex inPlaylist:(NSInteger)playlistIndex {
    currentSongIdx = songIndex;
    currentPlaylistIdx = playlistIndex;
    currentPlaylist = playlists[currentPlaylistIdx];
    currentSong = currentPlaylist[@"entry"][currentSongIdx];
    [as stop];
    as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
    [as start];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    /*for (UITableViewCell *cell in [[songTable visibleCells] copy]) {
        [songTable reloadRowsAtIndexPaths:@[[songTable indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationNone];
    }*/
}

-(void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([as isWaiting]) {
	} else if ([as isPlaying]) {
    } else if ([as isIdle]) {
        [self playNextSong];
	} else if ([as isPaused]) {
    }
}

- (void) togglePlayback {
    if ([as isPlaying])
        [as pause];
    else [as start];
}

- (void) playPreviousSong {
    if ([as progress]/[currentSong[@"duration"] intValue] < 0.05 && currentSongIdx>0)
        currentSongIdx--;
    [as stop];
    if (currentSongIdx >= 0) {
        currentSong = currentPlaylist[@"entry"][currentSongIdx];
        as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
        [as start];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
    } else {
        currentSongIdx++;
    }
}

- (void) playNextSong {
    currentSongIdx++;
    [as stop];
    if ([currentPlaylist[@"entry"] count] > currentSongIdx) {
        currentSong = currentPlaylist[@"entry"][currentSongIdx];
        as = [[AudioStreamer alloc] initWithURL:[[SubsonicRequestManager sharedInstance] getStreamURLForID:currentSong[@"id"]]];
        [as start];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
    } else {
        currentSongIdx--;
    }
}

- (void) seekToTime:(float)time {
    [as seekToTime:time];
}

- (void) seekToPercent:(float)percent {
    [as seekToTime:percent*[currentSong[@"duration"] intValue]];
}

- (NSInteger) playSong:(NSMutableDictionary *)song {
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    [playlists replaceObjectAtIndex:0 withObject:[@{@"entry":[[NSMutableArray alloc] initWithObjects:song,nil], @"name":@"On The Fly Playlist", @"temporary":@YES} mutableCopy]];
    currentPlaylistIdx = 0;
    currentSongIdx = 0;
    currentSong = song;
    currentPlaylist = playlists[0];
    [as stop];
    as = [[AudioStreamer alloc] initWithURL:songURL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:ASStatusChangedNotification
                                               object:as];
    [as start];
    [self writePlaylistsToFile];
    return currentPlaylistIdx;
}

- (void) playSongs:(NSMutableArray *)songs {
    NSInteger newPlaylist = [self playSong:songs[0]];
    for (int i=0;i<[songs count];i++) {
        [self addSong:songs[i] toPlaylistWithIndex:newPlaylist];
    }

}

- (void) addSong:(NSMutableDictionary *)song toPlaylistWithIndex:(NSInteger)playlistIndex {
    NSURL *songURL = [[SubsonicRequestManager sharedInstance] getStreamURLForID:song[@"id"]];
    [playlists[playlistIndex][@"entry"] addObject:song];
    playlists[playlistIndex][@"canBeReplaced"] = @NO;
    if (playlistIndex == currentPlaylistIdx && [playlists[playlistIndex][@"entry"] count] == (currentSongIdx+1) && [as isIdle]) {
        [as stop];
        as = [[AudioStreamer alloc] initWithURL:songURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackStateChanged:)
                                                     name:ASStatusChangedNotification
                                                   object:as];
        currentSong = song;
        [as start];
    }
    [self writePlaylistsToFile];
}

- (void) addSongs:(NSMutableArray *)songs toPlaylistWithIndex:(NSInteger)playlistIndex {
    for (int i=0;i<[songs count];i++) {
        [self addSong:songs[i] toPlaylistWithIndex:playlistIndex];
    }
}

#pragma mark - SubsonicPlaylistRequestProtocol

- (void) playlistRequestDidFail {
    
}

- (void) playlistRequestDidSucceedwithPlaylists:(NSMutableArray *)thePlaylists {
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *playlistFile = [cacheDirectory stringByAppendingPathComponent:@"playlists.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:playlistFile]) {
        NSMutableArray *playlistsFromFile = [[NSMutableArray alloc] initWithContentsOfFile:playlistFile];
        playlists = playlistsFromFile;
    } else {
        playlists = [@[] mutableCopy];
    }
    [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        obj[@"temporary"] = @NO;
    }];
    NSMutableArray *conflicts = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *serverPlaylist in thePlaylists) {
        NSUInteger conflictIdx = [playlists indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *pl = obj;
            if (pl[@"id"] == serverPlaylist[@"id"]) {
                return YES;
            }
            if ([pl[@"name"] isEqualToString:serverPlaylist[@"name"]]) {
                return YES;
            }
            return NO;
        }];
        serverPlaylist[@"canBeReplaced"] = @YES;
        serverPlaylist[@"temporary"] = @NO;
        if (conflictIdx == NSNotFound) {
            [playlists addObject:serverPlaylist];
        } else {
            NSMutableDictionary *conflictPlaylist = playlists[conflictIdx];
            BOOL shouldReplace = FALSE;
            if ([conflictPlaylist[@"canBeReplaced"] isEqualToNumber:@NO]) {
                shouldReplace = FALSE;
            } else {
                if ([conflictPlaylist[@"entry"] count] != [serverPlaylist[@"entry"] count]) {
                    shouldReplace = TRUE;
                } else {
                    if ([conflictPlaylist[@"entry"] count] == 0) shouldReplace = TRUE;
                    for (int i=0;i<[conflictPlaylist[@"entry"] count];i++) {
                        if (conflictPlaylist[@"entry"][i][@"id"] != serverPlaylist[@"entry"][i][@"id"]) {
                            shouldReplace = TRUE;
                            break;
                        }
                    }
                }
            }
            if (shouldReplace) {
                [playlists replaceObjectAtIndex:conflictIdx withObject:serverPlaylist];
            } else {
                [playlists addObject:serverPlaylist];
                [conflicts addObject:@{
                 @"localPlaylist":conflictPlaylist,
                 @"serverPlaylist":serverPlaylist
                 }];
            }
        }
    }
    [playlists sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[@"name"] compare:obj2[@"name"] options:NSCaseInsensitiveSearch|NSNumericSearch];
    }];
    NSString *temporaryPlaylistFile = [cacheDirectory stringByAppendingPathComponent:@"tempPlaylist.plist"];
    NSMutableDictionary *tempPlaylist;
    if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPlaylistFile]) {
        tempPlaylist = [[NSMutableDictionary alloc] initWithContentsOfFile:temporaryPlaylistFile];
    } else {
        tempPlaylist = [@{@"entry":[[NSMutableArray alloc] init],@"name":@"On The Fly Playlist",@"temporary":@YES} mutableCopy];
        [tempPlaylist writeToFile:temporaryPlaylistFile atomically:YES];
    }
    [playlists insertObject:tempPlaylist atIndex:0];
    currentPlaylistIdx = 0;
    currentSongIdx = 0;
    currentPlaylist = playlists[currentPlaylistIdx];
    currentSong = currentPlaylist[@"entry"][currentSongIdx];
    [SVProgressHUD dismiss];
    if ([conflicts count] > 0) {
      //  [self performSegueWithIdentifier:@"ConflictResolutionSegue" sender:self context:conflicts];
    }
}

- (void) playlistSyncDidSucceed {
    for (NSMutableDictionary *playlistToUpdate in playlists) {
        playlistToUpdate[@"canBeReplaced"] = @YES;
    }
    [self writePlaylistsToFile];
    [[SubsonicRequestManager sharedInstance] getPlaylistsWithDelegate:self];
}

@end
