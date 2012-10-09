//
//  SubsonicRequestManager.h
//  PadSonic
//
//  Created by Ben Weitzman on 10/7/12.
//  Copyright (c) 2012 Ben Weitzman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONKit.h"
typedef enum {
    ServerErrorBadConnection,
    ServerErrorBadCredentials,
    ServerErrorUnauthorizedOperation,
    ServerErrorMissingParameter,
    ServerErrorNoLicense,
    ServerErrorDataNotFound,
    ServerErrorUnknownError
} SubsonicServerError;

@protocol SubsonicArtistSectionsRequestDelegate, SubsonicArtistAlbumsRequestDelegate, SubsonicAlbumSongsRequestDelegate, SubsonicArtistSongsRequestDelegate, SubsonicAlbumCoverRequestDelegate, SubsonicPingRequestDelegate, SubsonicResetSessionDelegate;

@interface SubsonicRequestManager : NSObject

@property (strong, nonatomic) NSString *server, *username, *password;

+ (id) sharedInstance;

- (void) getArtistSectionsForMusicFolder:(NSInteger) musicFolderID delegate:(NSObject <SubsonicArtistSectionsRequestDelegate> *) delegate;
- (void) getAlbumsForArtistID:(NSString *)artistID delegate:(NSObject <SubsonicArtistAlbumsRequestDelegate> *) delegate;
- (void) getSongsForAlbumID:(NSString *) albumID delegate:(NSObject <SubsonicAlbumSongsRequestDelegate> *) delegate;
- (void) getSongsForArtistID:(NSString *) artistID delegate:(NSObject <SubsonicArtistSongsRequestDelegate> *)delegate;
- (void) getCoverArtForID:(NSString *) coverID delegate:(NSObject <SubsonicAlbumCoverRequestDelegate> *)delegate;
- (void) pingServerWithDelegate:(NSObject <SubsonicPingRequestDelegate> *) delegate;
- (void) resetSessionWithDelegate:(NSObject <SubsonicResetSessionDelegate> *)delegate;

@end

@protocol SubsonicArtistSectionsRequestDelegate <NSObject>

- (void) artistSectionsRequestDidFail;
- (void) artistSectionsRequestDidSucceedWithSections:(NSDictionary *)sections;

@end

@protocol SubsonicArtistAlbumsRequestDelegate <NSObject>

- (void) artistAlbumsRequestDidFail;
- (void) artistAlbumsRequestDidSucceedWithAlbums:(NSArray *) albums;

@end

@protocol SubsonicAlbumSongsRequestDelegate <NSObject>

- (void) albumSongsRequestDidFail;
- (void) albumSongsRequestDidSucceedWithSongs:(NSArray *) songs;

@end

@protocol SubsonicArtistSongsRequestDelegate <NSObject>

- (void) artistSongsRequestDidFail;
- (void) artistSongsRequestDidSucceedWithSongs:(NSDictionary *) songs;

@end

@protocol SubsonicAlbumCoverRequestDelegate <NSObject>

- (void) albumCoverRequestDidFail;
- (void) albumCoverRequestDidSucceedWithImage:(UIImage *) cover;

@end

@protocol SubsonicPingRequestDelegate <NSObject>

- (void) pingRequestDidFailWithError:(SubsonicServerError)error;
- (void) pingRequestDidSucceed;

@end

@protocol SubsonicResetSessionDelegate <NSObject>

- (void) resetSessionDidFinish;

@end