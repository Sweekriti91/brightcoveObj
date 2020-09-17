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
#import "AMPASCastChannel.h"

#define GOOGLE_SUPPORTED_CODECS_FORMAT @"{\"audioSpecList\": [%@]}"
#define CODECS_NAMES_LIST @[@"mp4a.40.2",@"ac-3",@"mp4a.a5",@"mp4a.a6",@"ec-3",@"mhm1.0x0D"]
#define CODECS_LIST @{@"mp4a.40.2" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"mp4a.40.2\"}",@"ac-3" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"ac-3\"}", @"mp4a.a5" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"mp4a.a5\"}", @"ec-3" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"ec-3\"}", @"mp4a.a6" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"mp4a.a6\"}", @"mhm1.0x0D" : @"{\"mimeType\": \"audio/mp4\", \"codecs\": \"mhm1.0x0D\"}"}
#define JOIN_STRING @","


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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveCastMessage:) name:AMPAS_CUSTOM_NOTIFICATION_NAME object:nil];
    }
    return self;
}

- (NSTimeInterval)currentProgress
{
    return _currentProgress > 0 ? _currentProgress : 0;
}

- (BCOVSource *)findPreferredSourceFromSources:(NSArray<BCOVSource *> *)sources withHTTPS:(BOOL)withHTTPS
{
    // Prioritize DASH > HLS v3 > MP4
    
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"url.absoluteString beginswith [cd] %@", withHTTPS ? @"https://" : @"http://"];
    NSArray *filteredSources = [sources filteredArrayUsingPredicate:protocolPredicate];
    
    BCOVSource *dashSource;
    BCOVSource *hlsSource;
    BCOVSource *mp4Source;
    
    for (BCOVSource *source in filteredSources) {
//        NSString *urlString = @"https://ampas-advanced.akamaized.net//wmt:eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg5NDlPU0NBUlNCUCIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MTcyMzUyMDAsImlhdCI6MTU4MzE5MDc4MSwiaXNzIjoiQU1QQVMiLCJ3bWlkIjoiQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJCQkJCQkJCQkJCQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFBQUFBQUFBQUFBQkJCQkJCQkJCQkFBQUFBQUFBQUEiLCJ3bWlkZm10IjoiYWIiLCJ3bXZlciI6MX0.lnwT3A46vKOmpzMc4rsPSOWTioJ9_cydeBBJN8ZkMYE6mJ7il-N46IEmz_BWXgnofYUeOiHspTCclhwGNoklN9PuIu5GCJ0fSNiMnTM3sdddLUDnxmoUzanVvmWM06416JBJqN9I7mJGoF5arnoCtrnrCwK3fxQF4QaMrXmbDw2UDoe0LGqpuHtdHkzz5GELPAehlZAkENv6PSivEjZOP2_vumj7V0KGFAYJHjH8qktWtKxnEGtRE2UyRFPKSpBK421wx3C2BGn_q0uLN6mkc_QABcfAN8nV_BmwwiL9Zx4XXd6FVMRoeRHkTJKhHqNhZhi1vSxJeeDh-tDjvmxObA/20BP_BestPic_FordVsFerrari_W_DYN_V2R1_1080_2CH_dash/20BP_BestPic_FordVsFerrari_W_DYN_V2R1_1080_2CH-playlist.mpd";
        NSString *deliveryMethod = source.deliveryMethod;
        if ([source.url.absoluteString containsString:@"dash"] && [deliveryMethod isEqualToString:@"application/dash+xml"]) {
            dashSource = source;
            // This is our top priority so we can go ahead and break out of the loop
            break;
        }
        if ([deliveryMethod isEqualToString:@"application/x-mpegURL"]) {
            hlsSource = source;
        }
        if ([deliveryMethod isEqualToString:@"video/mp4"]) {
            mp4Source = source;
        }
    }
    
    if (dashSource)
    {
        return dashSource;
    }
    else if (hlsSource)
    {
        return hlsSource;
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
    
    NSDictionary *licenseHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:@"PEtleU9TQXV0aGVudGljYXRpb25YTUw+PERhdGE+PEdlbmVyYXRpb25UaW1lPjIwMjAtMDktMTYgMTk6MTU6MTguNDIyPC9HZW5lcmF0aW9uVGltZT48RXhwaXJhdGlvblRpbWU+MjAyMC0wOS0yMyAxOToxNToxOC40MjI8L0V4cGlyYXRpb25UaW1lPjxVbmlxdWVJZD41ZGI0MTFiMWQ0YjU0MTQ1ODkwMTc0NzE3ZjBmNjlmOTwvVW5pcXVlSWQ+PFJTQVB1YktleUlkPmYyNDhlZDQ1MjQ5M2M3NzA2NWMwMzBmYTlhZjk3YjZiPC9SU0FQdWJLZXlJZD48V2lkZXZpbmVQb2xpY3kgZmxfQ2FuUGxheT0idHJ1ZSIgZmxfQ2FuUGVyc2lzdD0iZmFsc2UiIC8+PFdpZGV2aW5lQ29udGVudEtleVNwZWMgVHJhY2tUeXBlPSJIRCI+PFNlY3VyaXR5TGV2ZWw+MTwvU2VjdXJpdHlMZXZlbD48L1dpZGV2aW5lQ29udGVudEtleVNwZWM+PEZhaXJQbGF5UG9saWN5IHBlcnNpc3RlbnQ9ImZhbHNlIiAvPjxMaWNlbnNlIHR5cGU9InNpbXBsZSIgLz48L0RhdGE+PFNpZ25hdHVyZT5JSE5nUGtqL3NTNDhvK014L1haTC9IQmNMb0FIYjY0QVpwZEo1NWx1dDgzOXFCUG9WRmwweUtBZzdjQ3Y0Q0puUFZXdGdLT1ZPZFUyV250VzQvYjIvSTVQSUVSa25UOEJKMzY2YXF6YXVBeVBsM1VqekFNV3VPUzJTcHR4eUF3L25RRUdhaFdSME5IYkFZdloyNHZmZHJDdVhoMnNJdGZzcmYrY0VlUGJneVNhcFcySW5GNUlSMnBIQ3B6S0JzdUNpQVByY1NCNzNMTUFtZFVSemdKd1M0ODVCZ3J1N0lZZVgzSi9WajVETzdLVDFQL1lYVkRIck5pdEVlSWRubFRZcGZmbGlFWGluVU5SRHJRZmpnOUZRRHFqY0h6cUZ5WEVOQzJuRDhzWDBhTnJ4NzUyMUVlQUc2QmdXeE9vdVFIajI2OXlNUnQzdUl3SElxa0JrdWM1cnc9PTwvU2lnbmF0dXJlPjwvS2V5T1NBdXRoZW50aWNhdGlvblhNTD4=", @"customdata", nil];

    
    NSDictionary *jsonObjDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"https://wv-keyos.licensekeyserver.com/", @"licenseUrl", licenseHeaders, @"licenseKeyHeaders", nil];
    
    GCKMediaInformationBuilder *builder = [[GCKMediaInformationBuilder alloc] init];
    builder.contentID = videoURL;
    builder.streamType = GCKMediaStreamTypeUnknown;
    builder.contentType = source.deliveryMethod;
    builder.metadata = metadata;
    builder.streamDuration = durationNumber.intValue;
    builder.mediaTracks = mediaTracks;
    builder.customData = jsonObjDict;

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
        [self addAMPASCustomChannel:castSession];
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

#pragma mark - AMPAS Custom Cast Channel - 5.1 Audio

- (void)addAMPASCustomChannel:(GCKCastSession *)session {
    AMPASCastChannel *ampasCastChannel = [[AMPASCastChannel alloc] initWithNamespace:AMPAS_CUSTOM_CHANNEL];
    [session addChannel: ampasCastChannel];
    [self sendTextMessageThroughCustomChannel:ampasCastChannel];
}

- (void)sendTextMessageThroughCustomChannel:(AMPASCastChannel *)ampasCastChannel {
    NSMutableArray *foundCodecsInSource = [[NSMutableArray alloc] init];
    // Search for codecs in the cast media info url
    if ([_castMediaInfo contentID]) {
        for (NSString *codecName in CODECS_LIST) {
            if ([[_castMediaInfo contentID] containsString:codecName]) {
                [foundCodecsInSource addObject:CODECS_LIST[codecName]];
            }
        }
        if ([foundCodecsInSource count] > 0) {
            // Join filtered codecs array into a string separated by comma
            NSString *joinedComponents = [foundCodecsInSource componentsJoinedByString:JOIN_STRING];
            NSString *codecs = [NSString stringWithFormat:GOOGLE_SUPPORTED_CODECS_FORMAT, joinedComponents];
            // Send list of codecs parsed from cast media info url
            [ampasCastChannel sendTextMessage:codecs error: nil];
        }
    }
    
}


- (void)didReceiveCastMessage:(NSNotification *)notification {
    // Receive the codecs supported from the Receiver
    if (notification.userInfo[MESSAGE_KEY]) {
        // Convert the message string into a NSDictionary
        NSString *message = notification.userInfo[MESSAGE_KEY];
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *codecsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"%@", codecsDictionary);
    }
}

@end
