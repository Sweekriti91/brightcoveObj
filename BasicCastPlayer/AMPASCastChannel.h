//
//  AMPASCastChannel.h
//  BasicCastPlayer
//
//  Created by Federico Nieto on 28/08/2020.
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>

#define AMPAS_CUSTOM_CHANNEL @"urn:x-cast:bc.cast.theacademy"
#define MESSAGE_KEY @"message"
#define AMPAS_CUSTOM_NOTIFICATION_NAME @"didReceiveCastMessage"

NS_ASSUME_NONNULL_BEGIN

@interface AMPASCastChannel : GCKGenericChannel

@end

NS_ASSUME_NONNULL_END
