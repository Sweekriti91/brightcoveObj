//
//  GoogleCastManager.m
//  BasicCastPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "GoogleCastManager.h"

#import <BrightcovePlayerSDK/BCOVVideo.h>
#import <BrightcovePlayerSDK/BCOVSource.h>
#import <BrightcovePlayerSDK/BCOVPlaybackSession.h>

#import <GoogleCast/GoogleCast.h>

@interface GoogleCastManager ()<GCKSessionManagerListener, GCKUIMediaControllerDelegate>

@property (nonatomic, strong) GCKMediaInformation *castMediaInfo;
@property (nonatomic, strong) GCKSessionManager *sessionManager;
@property (nonatomic, strong) GCKUIMediaController *castMediaController;
@property (nonatomic, assign) NSTimeInterval currentProgress;
@property (nonatomic, assign) NSTimeInterval castStreamPosition;
@property (nonatomic, strong) BCOVVideo *currentVideo;
@property (nonatomic, assign) BOOL didContinueCurrentVideo;
@property (nonatomic, assign) BOOL suitableSourceNotFound;
@property (nonatomic, assign) CGSize posterImageSize;

@end

@implementation GoogleCastManager

- (instancetype)init
{
    if (self = [super init])
    {
        _sessionManager = [GCKCastContext sharedInstance].sessionManager;
        [_sessionManager addListener:self];
        _castMediaController = [[GCKUIMediaController alloc] init];
        _castMediaController.delegate = self;
        _posterImageSize = CGSizeMake(480, 720);
    }
    return self;
}

- (NSTimeInterval)currentProgress
{
    return _currentProgress > 0 ? _currentProgress : 0;
}

- (BCOVSource *)findPreferredSourceFromSources:(NSArray<BCOVSource *> *)sources withHTTPS:(BOOL)withHTTPS
{
    // We prioritize HLS v3 > DASH > MP4
    
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"url.absoluteString beginswith [cd] %@", withHTTPS ? @"https://" : @"http://"];
    NSArray *filteredSources = [sources filteredArrayUsingPredicate:protocolPredicate];
    
    BCOVSource *hlsSource;
    BCOVSource *dashSource;
    BCOVSource *mp4Source;
    
    for (BCOVSource *source in filteredSources) {
        NSString *urlString = source.url.absoluteString;
        NSString *deliveryMethod = source.deliveryMethod;
        if ([urlString containsString:@"hls/v3"] && [deliveryMethod isEqualToString:@"application/x-mpegURL"]) {
            hlsSource = source;
            // This is our top priority so we can go ahead and break out of the loop
            break;
        }
        if ([deliveryMethod isEqualToString:@"application/dash+xml"]) {
            dashSource = source;
        }
        if ([deliveryMethod isEqualToString:@"video/mp4"]) {
            mp4Source = source;
        }
    }
    
    if (hlsSource)
    {
        return hlsSource;
    }
    else if (dashSource)
    {
        return dashSource;
    }
    else if (mp4Source)
    {
        return mp4Source;
    }
        
    return nil;
}

#pragma mark - Casting Methods

- (void)createMediaInfoFromVideo:(BCOVVideo *)video
{
    BCOVSource *source;
    
    // Don't restart the current video
    self.didContinueCurrentVideo = [self.currentVideo isEqualToVideo:video];
    if (self.didContinueCurrentVideo)
    {
        return;
    }
    
    self.suitableSourceNotFound = NO;
    
    // Try to find an HTTPS source first
    source = [self findPreferredSourceFromSources:video.sources withHTTPS:YES];
    
    // If one is not found, accept an HTTP source
    if (!source)
    {
       source = [self findPreferredSourceFromSources:video.sources withHTTPS:NO];
    }
    
    // If no source was able to be found, let the delegate know
    // and do not continue
    if (!source)
    {
        self.suitableSourceNotFound = YES;
        if ([self.delegate respondsToSelector:@selector(suitableSourceNotFound)]) {
            [self.delegate suitableSourceNotFound];
        }
        return;
    }
    
    self.currentVideo = video;
    
    NSString *videoURL = source.url.absoluteString;
    NSString *name = video.properties[kBCOVVideoPropertyKeyName];
    NSNumber *durationNumber = video.properties[kBCOVVideoPropertyKeyDuration];
    
    GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeGeneric];
    [metadata setString:name forKey:kGCKMetadataKeyTitle];
    
    NSString *poster = video.properties[kBCOVVideoPropertyKeyPoster];
    if (poster)
    {
        NSURL *imageURL = [NSURL URLWithString:poster];
        if (imageURL)
        {
            [metadata addImage:[[GCKImage alloc] initWithURL:imageURL width:self.posterImageSize.width height:self.posterImageSize.height]];
        }
    }

    NSMutableArray *mediaTracks = @[].mutableCopy;

    NSArray *textTracks = video.properties[kBCOVVideoPropertyKeyTextTracks];
    
    NSInteger trackIdentifier = 0;
    
    for (NSDictionary *track in textTracks) {
        trackIdentifier += 1;
        NSString *src = track[@"src"];
        NSString *lang = track[@"srclang"];
        NSString *name = track[@"label"];
        NSString *contentType = track[@"mime_type"];
        if ([contentType isEqualToString:@"text/webvtt"])
        {
            // The Google Cast SDK doesn't seem to understand text/webvtt
            // Simply setting the content type as text/vtt seems to work
            contentType = @"text/vtt";
        }
        NSString *kind = track[@"kind"];
        GCKMediaTextTrackSubtype trackType = GCKMediaTextTrackSubtypeUnknown;
        if ([kind isEqualToString:@"captions"] || [kind isEqualToString:@"subtitles"])
        {
            trackType = [kind isEqualToString:@"captions"] ? GCKMediaTextTrackSubtypeCaptions : GCKMediaTextTrackSubtypeSubtitles;
            GCKMediaTrack *captionsTrack = [[GCKMediaTrack alloc] initWithIdentifier:trackIdentifier
                                                                   contentIdentifier:src
                                                                         contentType:contentType
                                                                                type:GCKMediaTrackTypeText
                                                                         textSubtype:trackType
                                                                                name:name
                                                                        languageCode:lang
                                                                          customData:nil];
            [mediaTracks addObject:captionsTrack];
        }
    }
    
    
    //FW thingy
    
    NSDictionary *licenseHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:@"PEtleU9TQXV0aGVudGljYXRpb25YTUw+PERhdGE+PEdlbmVyYXRpb25UaW1lPjIwMjAtMDYtMjkgMjI6MTU6NTguMTU1PC9HZW5lcmF0aW9uVGltZT48RXhwaXJhdGlvblRpbWU+MjAyMC0wNy0wNCAyMjoxNTo1OC4xNTU8L0V4cGlyYXRpb25UaW1lPjxVbmlxdWVJZD5hNDMzMmEyNDNkZDA0YzhlYjk2YjkzNDhjNTQ3MWQwYTwvVW5pcXVlSWQ+PFJTQVB1YktleUlkPmYyNDhlZDQ1MjQ5M2M3NzA2NWMwMzBmYTlhZjk3YjZiPC9SU0FQdWJLZXlJZD48V2lkZXZpbmVQb2xpY3kgZmxfQ2FuUGxheT0idHJ1ZSIgZmxfQ2FuUGVyc2lzdD0iZmFsc2UiIC8+PFdpZGV2aW5lQ29udGVudEtleVNwZWMgVHJhY2tUeXBlPSJIRCI+PFNlY3VyaXR5TGV2ZWw+MTwvU2VjdXJpdHlMZXZlbD48L1dpZGV2aW5lQ29udGVudEtleVNwZWM+PEZhaXJQbGF5UG9saWN5IHBlcnNpc3RlbnQ9ImZhbHNlIiAvPjxMaWNlbnNlIHR5cGU9InNpbXBsZSIgLz48L0RhdGE+PFNpZ25hdHVyZT5VNDY1aEJmdFo5QXhUSTB1VDhqUjZKQXY0TytCZ1hJT1BYdkZTMnlpUmprT3NPbURiUzByQTVPYVZVdzRLdTdrNnNNUlNkWlhFZEdTdDFVOGdMemVXU1BaRitUM2JKRXQ5S2QzdUZMeS85RkQ1akw2NWUvTS93ZTI4bkJCalU2dldLL1RraklTMG5qY1Z3QnVVOWIzV3h6cHduSnRkRmZobzhWU1RGK2JyNjhWdS9pckNzMHJ3d2xOTGw0RmhheXVkSXlFODdLemVoTXZ5R2lLMXNmckloSVp5eXlGQlVZeGljOWQ1WXJzdWJlZEN1ZnNPbkNueWxhaFNvWUF4MmFPR1RUQlRkRWJPUGxSSFcvUmJvbWhmK2dpSGY0L0xSc2VJcXJ3QmNnRm1MNHZWZ2I4bXNWYzVaZExQdG1KRkZPZWlVcGVMUzZMQ2hhbGpma3FqZUxSQWc9PTwvU2lnbmF0dXJlPjwvS2V5T1NBdXRoZW50aWNhdGlvblhNTD4=", @"customdata", nil];

    
    NSDictionary *jsonObjDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"https://wv-keyos.licensekeyserver.com/", @"licenseUrl", licenseHeaders, @"licenseKeyHeaders", nil];

    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObjDict options:NSJSONWritingPrettyPrinted error:nil];
    
    GCKMediaInformationBuilder *builder = [[GCKMediaInformationBuilder alloc] init];
    builder.contentID = videoURL;
    builder.streamType = GCKMediaStreamTypeUnknown;
    builder.contentType = source.deliveryMethod;
    builder.metadata = metadata;
    builder.streamDuration = durationNumber.intValue;
    builder.mediaTracks = mediaTracks;
    builder.customData = data;

    self.castMediaInfo = [builder build];
}

- (void)setupRemoteMediaClientWithMediaInfo
{
    // Don't load media if the video is what is already playing
    // or if we couldn't find a suitable source for the video
    if (self.didContinueCurrentVideo || self.suitableSourceNotFound)
    {
        return;
    }
    GCKCastSession *castSession = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    GCKMediaLoadOptions *options = [GCKMediaLoadOptions new];
    options.playPosition = self.currentProgress;
    options.autoplay = self.delegate.playbackController.isAutoPlay;
    if (castSession)
    {
        [castSession.remoteMediaClient loadMedia:self.castMediaInfo withOptions:options];
    }
}

- (void)switchToRemotePlayback
{
    // Pause local player
    [self.delegate.playbackController pause];
    if ([self.delegate respondsToSelector:@selector(switchedToRemotePlayback)])
    {
        [self.delegate switchedToRemotePlayback];
    }
}

- (void)switchToLocalPlaybackWithError:(NSError *)error
{
    // Play local player
    NSTimeInterval lastKnownStreamPosition = self.castMediaController.lastKnownStreamPosition;
    
    __weak typeof(self) weakSelf = self;
    [self.delegate.playbackController seekToTime:CMTimeMakeWithSeconds(lastKnownStreamPosition, 600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(switchedToLocalPlayback:withError:)])
        {
            [strongSelf.delegate switchedToLocalPlayback:lastKnownStreamPosition withError:error];
        }
        
    }];
}

#pragma mark - GCKSessionManagerListener

- (void)sessionManager:(GCKSessionManager *)sessionManager didStartSession:(GCKSession *)session
{
    [self switchToRemotePlayback];
    [self setupRemoteMediaClientWithMediaInfo];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didResumeSession:(GCKSession *)session
{
    [self switchToRemotePlayback];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didEndSession:(GCKSession *)session
             withError:(NSError *)error
{
    [self switchToLocalPlaybackWithError:error];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didFailToStartSessionWithError:(NSError *)error
{
    [self switchToLocalPlaybackWithError:error];
}

#pragma mark - BCOVPlaybackSessionConsumer Methods

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    [self createMediaInfoFromVideo:session.video];
    [self setupRemoteMediaClientWithMediaInfo];
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    self.currentProgress = progress;
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventReady] && [GCKCastContext sharedInstance].sessionManager.currentCastSession)
    {
        [self switchToRemotePlayback];
    }
}

#pragma mark - GCKUIMediaControllerDelegate

- (void)mediaController:(GCKUIMediaController *)mediaController didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus
{
    // Once the video has finished, let the delegate know
    // and attempt to proceed to the next session, if autoAdvance
    // is enabled
    if (mediaStatus.idleReason == GCKMediaPlayerIdleReasonFinished)
    {
        
        if ([self.delegate respondsToSelector:@selector(castedVideoDidComplete)])
        {
            self.currentVideo = nil;
            [self.delegate castedVideoDidComplete];
        }
        
        if (self.delegate.playbackController.isAutoAdvance)
        {
            [self.delegate.playbackController advanceToNext];
        }

    }
    
    if (mediaStatus.idleReason == GCKMediaPlayerIdleReasonError)
    {
        if ([self.delegate respondsToSelector:@selector(castedVideoFailedToPlay)])
        {
            self.currentVideo = nil;
            [self.delegate castedVideoFailedToPlay];
        }
    }
    
    self.castStreamPosition = mediaStatus.streamPosition;
}

@end
