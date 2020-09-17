//
//  AMPASCastChannel.m
//  BasicCastPlayer
//
//  Created by Federico Nieto on 28/08/2020.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import "AMPASCastChannel.h"


@implementation AMPASCastChannel

- (void)didReceiveTextMessage:(NSString *)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:AMPAS_CUSTOM_NOTIFICATION_NAME  object:nil userInfo:@{MESSAGE_KEY : message}];
}

@end
