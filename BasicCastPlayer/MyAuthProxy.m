//
//  MyAuthProxy.m
//  VideoCloudBasicPlayer
//
//  Created by Tatsuo Hase on 11/6/19.
//  Copyright © 2019 Brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyAuthProxy.h"

@interface MyAuthProxy ()
@property (nonatomic, copy) NSString *applicationId;
@property (nonatomic, copy) NSString *publisherId;
@end

@implementation MyAuthProxy
static NSString *customDataHeader = @"PEtleU9TQXV0aGVudGljYXRpb25YTUw+PERhdGE+PEdlbmVyYXRpb25UaW1lPjIwMjAtMTAtMjYgMjA6NTY6MjIuNDY1PC9HZW5lcmF0aW9uVGltZT48RXhwaXJhdGlvblRpbWU+MjAyMC0xMS0wOSAyMDo1NjoyMi40NjY8L0V4cGlyYXRpb25UaW1lPjxVbmlxdWVJZD45NzE4Y2ZmZTI5Mjg0MWM3YWUwNzA1MDZkOTY3MTg2OTwvVW5pcXVlSWQ+PFJTQVB1YktleUlkPmYyNDhlZDQ1MjQ5M2M3NzA2NWMwMzBmYTlhZjk3YjZiPC9SU0FQdWJLZXlJZD48V2lkZXZpbmVQb2xpY3kgZmxfQ2FuUGxheT0idHJ1ZSIgZmxfQ2FuUGVyc2lzdD0iZmFsc2UiIC8+PFdpZGV2aW5lQ29udGVudEtleVNwZWMgVHJhY2tUeXBlPSJIRCI+PFNlY3VyaXR5TGV2ZWw+MTwvU2VjdXJpdHlMZXZlbD48L1dpZGV2aW5lQ29udGVudEtleVNwZWM+PEZhaXJQbGF5UG9saWN5IHBlcnNpc3RlbnQ9ImZhbHNlIiAvPjxMaWNlbnNlIHR5cGU9InNpbXBsZSIgLz48L0RhdGE+PFNpZ25hdHVyZT5YS05aOSs4aEc5RGlxSHM2YVRUMmcyMFQvdGJJdFhNajJqdDdYdzlwVEl2cm55bDB4RzVIRmFwa1Z1b0xLckFGYS9BWUYrUjZNOGNvK1FLTlF0Ly9iMDRralMxcEFKOCswTDgvOXp2TFlaMlpqZnNKZTBpdXpEQjdBMnFaTk4yM1A3bHE5Z3RxUXYzZmw0MkkxVGFscWxoU1BhelNZTUdIanZNWjh1QTMrUi9YNnZ0STB2OEJrdGFZU2kvSzNKTS94NUJLbmhkTkxnOENRbzRsU3NWL2NCRVFtamZrSEZsS3hrc3RDQlFheG1lV1ZRWkRSQ2NiQlgreTVRRjZHaXRpQ1lyZGZwUVlLbndtc3pzTy83MEJpT1BKaDRjbStaR0tJVHl3QkhpSmNKZUdTRzVEdFdJOCs5TFM1SWowZlJ0MGxwOSsrWjZKbncreHFKY1ZsQ25qbXc9PTwvU2lnbmF0dXJlPjwvS2V5T1NBdXRoZW50aWNhdGlvblhNTD4=";


- (void)encryptedContentKeyForContentKeyIdentifier:(NSString *)contentKeyIdentifier // the "skd://..." url string
                                 contentKeyRequest:(NSData *)keyRequest // SPC
                                            source:(BCOVSource *)source
                                           options:(NSDictionary *)options
                                 completionHandler:(void (^)(NSURLResponse * _Nullable,
                                                             NSData * _Nullable,
                                                             NSError * _Nullable))completionHandler
{
    NSURL *loadingRequestURL = [NSURL URLWithString:contentKeyIdentifier];
    NSString *keyId = [loadingRequestURL lastPathComponent];
    NSString *base64spc = [keyRequest base64EncodedStringWithOptions:0];
    
    // It's ok if the applicationId or publisherId is nil
    if (self.publisherId == nil)
    {
        self.publisherId = @"";
    }
    
    if (self.applicationId == nil)
    {
        self.applicationId = @"";
    }
    
    if (keyId == nil)
    {
        keyId = @"";
    }
    
    if (base64spc == nil)
    {
        base64spc = @"";
    }
    
    NSDictionary *postBodyParams =
    @{
      @"publisher_id" : self.publisherId,
      @"application_id" : self.applicationId,
      @"key_id" : keyId,
      @"server_playback_context" : base64spc
      };
    
    NSError *jsonError;
    NSData *json = [NSJSONSerialization dataWithJSONObject:postBodyParams options:0 error:&jsonError];
    
    if (json)
    {
        NSURL *url;
        
        // If present, use the overridden key request URL.
        if (self.keyRequestURL != nil)
        {
            url = self.keyRequestURL;
        }
        else
        {
            // Look for the key request url in the video properties
            NSString *keyRequestURL = source.properties[kBCOVSourcePropertyKeySystems][kBCOVSourceKeySystemFairPlayV1][kBCOVSourceKeySystemFairPlayKeyRequestURLKey];
            
            if (keyRequestURL)
            {
                url = [NSURL URLWithString:keyRequestURL];
            }
            
            // In case the URL conversion above failed, or there was no key systems in the source.
            if (!url)
            {
                NSString *requestPath = @"fairplay_session_playback";
                url = [NSURL URLWithString:requestPath relativeToURL:self.fpsBaseURL];
            }
        }
        
        // Brightcove TS: Added these line to extrace the spc value
        NSRange skdRange = [contentKeyIdentifier rangeOfString:@"skd://"];
        NSString* spcValue = [contentKeyIdentifier substringFromIndex:skdRange.length];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:customDataHeader forHTTPHeaderField:@"customdata"];

        // If there is no AuthToken stored on BCOVAuthManager.sharedMananger, this header will not be added
        // Brightcove TS: Delete this line below it's not used
        //[[BCOVAuthManager sharedManager] addAuthTokenHeaderToRequest:request];

        // Brightcove TS: Need to change the body.
        NSString *raw = [NSString stringWithFormat:@"spc=%@&assetId=%@", base64spc, spcValue];
        NSData* mydata = [raw dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = mydata;
        // Brightcove TS: Deleted this original line.
        //request.HTTPBody = json;
        
        NSURLSessionDataTask *task = [self.sharedURLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

            if (error)
            {
                NSString *desc = @"Call to -[BCOVFPSBrightcoveAuthProxy encryptedContentKeyForContentKeyIdentifier:contentKeyRequest:source:options:completionHandler:] failed. NSURLSessionDataTask failed.";
                NSString *recovery = @"There is no recovery from this error. Internet may be down.";
                NSDictionary *userInfo = @{
                                           
                                           NSLocalizedDescriptionKey: desc,
                                           NSLocalizedRecoverySuggestionErrorKey: recovery,
                                           NSUnderlyingErrorKey : error
                                           
                                           };
                
                NSError *contentKeyError = [NSError errorWithDomain:kBCOVFPSAuthProxyErrorDomain code:kBCOVFPSAuthProxyErrorCodeContentKeyRequestFailed userInfo:userInfo];
                completionHandler(nil, nil, contentKeyError);
            }
            else
            {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
                {
                    // Decode the key returned instead of directly passing to "completionHandler"
                    NSString *base64 = [[NSString alloc] initWithData:data encoding:kCFStringEncodingUTF8];
                    NSData *base64Decoded = [[NSData alloc] initWithBase64EncodedString:base64 options:0];

                    completionHandler(response, base64Decoded, nil);
                }
                else
                {
                    NSString *desc = [NSString stringWithFormat:@"Call to -[BCOVFPSBrightcoveAuthProxy encryptedContentKeyForContentKeyIdentifier:contentKeyRequest:source:options:completionHandler:] failed. Invalid HTTP status code `%@` returned.", @( httpResponse.statusCode )];
                    NSString *recovery = @"There is no recovery from this error.";
                    NSDictionary *userInfo = @{
                                               
                                               NSLocalizedDescriptionKey: desc,
                                               NSLocalizedRecoverySuggestionErrorKey: recovery
                                               
                                               };
                    
                    NSError *contentKeyError = [NSError errorWithDomain:kBCOVFPSAuthProxyErrorDomain code:kBCOVFPSAuthProxyErrorCodeContentKeyRequestFailed userInfo:userInfo];
                    completionHandler(response, nil, contentKeyError);
                }
            }
            
        }];
        [task resume];
    }
    else
    {
        NSString *desc = @"Call to -[BCOVFPSBrightcoveAuthProxy encryptedContentKeyForContentKeyIdentifier:contentKeyRequest:source:options:completionHandler:] failed. NSJSONSerialization dataWithJSONObject failed.";
        NSString *recovery = @"There is no recovery from this error.";
        NSMutableDictionary *userInfo = NSMutableDictionary.dictionary;
        userInfo[NSLocalizedDescriptionKey] = desc;
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recovery;
        if (jsonError != nil)
        {
            userInfo[NSUnderlyingErrorKey] = jsonError;
        };
        
        NSError *contentKeyError = [NSError errorWithDomain:kBCOVFPSAuthProxyErrorDomain code:kBCOVFPSAuthProxyErrorCodeContentKeyGenerationFailed userInfo:userInfo];
        
        completionHandler(nil, nil, contentKeyError);
    }
}
@end
