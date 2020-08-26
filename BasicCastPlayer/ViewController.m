//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

#import "ViewController.h"
#import "GoogleCastManager.h"
#import "MyAuthProxy.h"

@import GoogleCast;
@import BrightcovePlayerSDK;
@import BrightcoveGoogleCast;

// ** Customize these values with your own account information **
//static NSString * const kViewControllerPlaybackServicePolicyKey = @"BCpkADawqM2KHxdGXcfkSRZbJ4Y7qHYVSijf-z7sDNII8bRdxDxay8NP9LaBDvoIiQOsQg34vP9Np_KGCz9Uw4UwtrDXzJgbve5P1QnKvtmwWh0Hfg1iYuhWICxUQ1fx8GnIkLvch7uv4aJI";
//static NSString * const kViewControllerAccountID = @"3636334164001";
//static NSString * const kViewControllerVideoID = @"5686335954001";

static NSString * const kSourceUrl = @"https://ampas-advanced.akamaized.net//wmt:eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg5NDlPU0NBUlNCUCIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MTcyMzUyMDAsImlhdCI6MTU4MzE5MDc4MSwiaXNzIjoiQU1QQVMiLCJ3bWlkIjoiQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQkJCQkJBQUFBQUJCQkJCQkJCQkJCQkJCQkFBQUFBQkJCQkJBQUFBQUJCQkJCQUFBQUFCQkJCQkJCQkJCQUFBQUFCQkJCQkFBQUFBQUFBQUFCQkJCQkFBQUFBQkJCQkJBQUFBQUFBQUFBQkJCQkJCQkJCQkFBQUFBQkJCQkJCQkJCQkJCQkJCQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUJCQkJCQUFBQUFBQUFBQUFBQUFBQkJCQkJCQkJCQkFBQUFBQUFBQUEiLCJ3bWlkZm10IjoiYWIiLCJ3bXZlciI6MX0.lnwT3A46vKOmpzMc4rsPSOWTioJ9_cydeBBJN8ZkMYE6mJ7il-N46IEmz_BWXgnofYUeOiHspTCclhwGNoklN9PuIu5GCJ0fSNiMnTM3sdddLUDnxmoUzanVvmWM06416JBJqN9I7mJGoF5arnoCtrnrCwK3fxQF4QaMrXmbDw2UDoe0LGqpuHtdHkzz5GELPAehlZAkENv6PSivEjZOP2_vumj7V0KGFAYJHjH8qktWtKxnEGtRE2UyRFPKSpBK421wx3C2BGn_q0uLN6mkc_QABcfAN8nV_BmwwiL9Zx4XXd6FVMRoeRHkTJKhHqNhZhi1vSxJeeDh-tDjvmxObA/20BP_BestPic_Bombshell_W_DYN_V1R0_1080_6CH_hls/20BP_BestPic_Bombshell_W_DYN_V1R0_1080_6CH-playlist.m3u8";
static NSString * const kRequestKeyUrl = @"https://fp-keyos.licensekeyserver.com/getkey";
static NSString * const kCertificateKeyUrl = @"https://fp-keyos.licensekeyserver.net/cert/f248ed452493c77065c030fa9af97b6b.der";

@interface ViewController ()<GoogleCastManagerDelegate, BCOVPlaybackControllerDelegate>


@property (nonatomic, strong) MyAuthProxy *fariPlayAuthProxy;

@property (nonatomic, strong) BCOVPlaybackService *playbackService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) GoogleCastManager *googleCastManager;


@end


@implementation ViewController

#pragma mark Setup Methods

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    MyAuthProxy *proxy = [[MyAuthProxy alloc] initWithPublisherId:nil applicationId:nil];
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
    _playbackController = [sdkManager createFairPlayPlaybackControllerWithAuthorizationProxy:proxy];

    self.playbackController.delegate = self;
    self.playbackController.autoAdvance = YES;
    self.playbackController.autoPlay = YES;
    

    
    // self.playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kViewControllerAccountID
    //                                                            policyKey:kViewControllerPlaybackServicePolicyKey];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:castButton];
    
        // If you need to extend the behavior of BCOVGoogleCastManager
        // you can customize the GoogleCastManager class in this project
        // and use it instead of BCOVGoogleCastManager.
        self.googleCastManager = [GoogleCastManager new];
        self.googleCastManager.delegate = self;
        NSLog(@"Using Customized GoogleCastManager");


    // Set up our player view. Create with a standard VOD layout.
    BCOVPUIPlayerViewOptions *options = [BCOVPUIPlayerViewOptions new];
    options.showPictureInPictureButton = YES;
    
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout] ];
//    playerView.delegate = self;

    [_videoContainer addSubview:playerView];
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [playerView.topAnchor constraintEqualToAnchor:_videoContainer.topAnchor],
                                              [playerView.rightAnchor constraintEqualToAnchor:_videoContainer.rightAnchor],
                                              [playerView.leftAnchor constraintEqualToAnchor:_videoContainer.leftAnchor],
                                              [playerView.bottomAnchor constraintEqualToAnchor:_videoContainer.bottomAnchor],
                                              ]];
    _playerView = playerView;
                      
    // Dummy Catalog call
    //[self requestContentFromPlaybackService];

    BCOVVideo* newVideo = [self createVideo];
    [self.playbackController setVideos:@[ newVideo ]];
        [self.playbackController addSessionConsumer:self.googleCastManager];
}

- (BCOVVideo*)createVideo
{
    NSMutableDictionary *videoPropertiesDictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray *updatedSources = [[NSMutableArray alloc] init];
    
    //videoPropertiesDictionary[@"druation"] = [[NSNumber alloc] initWithLong:15000l]; // in seconds
    
    NSMutableDictionary *mutableSource = [[NSMutableDictionary alloc] init];
    
    // ----------------------------------------
    // BCOVSource setup
    // ----------------------------------------
    mutableSource[@"src"] = kSourceUrl;
    mutableSource[@"ext_x_version"] = @"5";
    mutableSource[@"type"] = @"application/x-mpegURL";
    
    NSMutableDictionary *mutableKeySystem = [[NSMutableDictionary alloc] init];
    [mutableKeySystem addEntriesFromDictionary: mutableSource[@"key_systems"]];
    
    NSMutableDictionary *mutableFPS = [[NSMutableDictionary alloc] init];
    [mutableFPS addEntriesFromDictionary: mutableKeySystem[@"com.apple.fps.1_0"]];
    
    mutableFPS[@"key_request_url"] = kRequestKeyUrl;
    mutableFPS[@"certificate_url"] = kCertificateKeyUrl;
    
    mutableKeySystem[@"com.apple.fps.1_0"] = mutableFPS;
    mutableSource[@"key_systems"] = mutableKeySystem;

    [updatedSources addObject:mutableSource];

    // Save the BCOVSource in "sources"
    videoPropertiesDictionary[@"sources"] = updatedSources;
    // Create BCOVVideo using the Dictionary
    BCOVVideo *newVideo = [BCOVPlaybackService videoFromJSONDictionary:videoPropertiesDictionary];
    
    return newVideo;
}

- (void)castDeviceDidChange:(NSNotification *)notification
{
    switch ([GCKCastContext sharedInstance].castState) {
        case GCKCastStateNoDevicesAvailable:
            NSLog(@"Cast Status: No Devices Available");
            break;
        case GCKCastStateNotConnected:
            NSLog(@"Cast Status: Not Connected");
            break;
        case GCKCastStateConnecting:
            NSLog(@"Cast Status: Connecting");
            break;
        case GCKCastStateConnected:
            NSLog(@"Cast Status: Connected");
            break;
    }
}


// Not Used
/*
- (BCOVVideo*)updateSources:(NSDictionary*)jsonResponse
{

    NSMutableDictionary *videoPropertiesDictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray *updatedSources = [[NSMutableArray alloc] init];
    
    [videoPropertiesDictionary addEntriesFromDictionary:jsonResponse];
    videoPropertiesDictionary[@"druation"] = [[NSNumber alloc] initWithLong:15000l]; // in seconds
    for (NSDictionary *source in videoPropertiesDictionary[@"sources"])
    {
        NSMutableDictionary *mutableSource = [[NSMutableDictionary alloc] init];
        [mutableSource addEntriesFromDictionary:source];
        
        mutableSource[@"src"] = kSourceUrl;
        mutableSource[@"ext_x_version"] = @"5";
        
        NSMutableDictionary *mutableKeySystem = [[NSMutableDictionary alloc] init];
        [mutableKeySystem addEntriesFromDictionary: mutableSource[@"key_systems"]];
        
        NSMutableDictionary *mutableFPS = [[NSMutableDictionary alloc] init];
        [mutableFPS addEntriesFromDictionary: mutableKeySystem[@"com.apple.fps.1_0"]];
        
        mutableFPS[@"key_request_url"] = kRequestKeyUrl;
        mutableFPS[@"certificate_url"] = kCertificateKeyUrl;
        
        mutableKeySystem[@"com.apple.fps.1_0"] = mutableFPS;
        mutableSource[@"key_systems"] = mutableKeySystem;

        [updatedSources addObject:mutableSource];
    }
    videoPropertiesDictionary[@"sources"] = updatedSources;
    
    // Create a new video object with the updated jsonResponse NSDictionary object
    BCOVVideo *newVideo = [BCOVPlaybackService videoFromJSONDictionary:videoPropertiesDictionary];
    
    return newVideo;
}

- (void)requestContentFromPlaybackService
{
    [self.playbackService findVideoWithVideoID:kViewControllerVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            BCOVVideo* newVideo = [self updateSources:jsonResponse];
 
            [self.playbackController setVideos:@[ newVideo ]];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving video playlist: `%@`", error);
        }

    }];
}
*/



#pragma mark - GoogleCastManagerDelegate

- (void)switchedToRemotePlayback
{
    self.videoContainer.hidden = YES;
}

- (void)switchedToLocalPlayback:(NSTimeInterval)lastKnownStreamPosition withError:(NSError *)error
{
    if (lastKnownStreamPosition > 0)
    {
        [self.playbackController play];
    }
    self.videoContainer.hidden = NO;
    
    if (error)
    {
        NSLog(@"Switched to local playback with error: %@", error.localizedDescription);
    }
}

- (void)castedVideoDidComplete
{
    self.videoContainer.hidden = YES;
}

- (void)suitableSourceNotFound
{
    NSLog(@"Suitable source for video not found!");
}

- (void)castedVideoFailedToPlay
{
    NSLog(@"Casted video failed to play!");
}
    
#pragma mark - BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    NSLog(@"Progress: %0.2f seconds", progress);
}

//- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
//{
//    if ([lifecycleEvent.eventType isEqualToString:kBCOVPlaybackSessionLifecycleEventEnd])
//    {
//        self.videoContainer.hidden = YES;
//    }
//}

#pragma mark - BCOVPUIPlayerViewDelegate

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerDidStartPictureInPicture");
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerDidStopPictureInPicture");
}

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerWillStartPictureInPicture");
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController
{
    NSLog(@"pictureInPictureControllerWillStopPictureInPicture");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error
{
    NSLog(@"failedToStartPictureInPictureWithError: %@", error.localizedDescription);
}

@end

