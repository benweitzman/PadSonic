//
//  PadsonicPlayerManager.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/18/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AudioStreamer.h"
#import "SubsonicRequestManager.h"


@interface PadsonicPlayerManager : NSObject <SubsonicPlaylistRequestDelegate, SubsonicPlaylistSyncDelegate>

@property (strong, nonatomic) NSMutableArray *playlists;
@property (nonatomic) NSInteger currentSongIdx;
@property (nonatomic) NSInteger currentPlaylistIdx;
@property (strong, nonatomic) NSMutableDictionary *currentPlaylist;
@property (strong, nonatomic) NSMutableDictionary *currentSong;
@property (strong, nonatomic) MPMoviePlayerViewController *mplayer;
@property (strong, nonatomic) AudioStreamer *as;

+ (id) sharedInstance;
- (void) writePlaylistsToFile;
- (void) addNewPlaylistWithName:(NSString *)name;
- (void) syncPlaylists;
- (void) playSongWithIndex:(NSInteger) songIndex inPlaylist:(NSInteger)playlistIndex;
- (void) togglePlayback;
- (void) playPreviousSong;
- (void) playNextSong;
- (void) seekToTime:(float) time;
- (void) seekToPercent:(float) percent;
- (NSInteger) playSong:(NSMutableDictionary*)song;
- (void) playSongs:(NSMutableArray *)songs;
- (void) addSong:(NSMutableDictionary *)song toPlaylistWithIndex:(NSInteger)playlistIndex;
- (void) addSongs:(NSMutableArray *)songs toPlaylistWithIndex:(NSInteger)playlistIndex;

@end
