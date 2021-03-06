/*   Copyright 2016 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ANInstreamVideoAd.h"
#import "ANVideoAdPlayer.h"
#import "ANUniversalAdFetcher.h"
#import "ANLogging.h"



//---------------------------------------------------------- -o--
NSString * const  exceptionCategoryAPIUsageErr  = @"API usage err.";




//---------------------------------------------------------- -o--
@interface  ANInstreamVideoAd()  <ANVideoAdPlayerDelegate, ANUniversalAdFetcherDelegate>

    @property  (weak, nonatomic, readwrite)  id<ANInstreamVideoAdLoadDelegate>  loadDelegate;
    @property  (weak, nonatomic, readwrite)  id<ANInstreamVideoAdPlayDelegate>  playDelegate;

    @property (nonatomic, strong)  ANVideoAdPlayer  *adPlayer;
    @property (nonatomic, strong)  UIView           *adContainer;

    //
    @property (strong, nonatomic, readwrite)  NSString  *descriptionOfFailure;
    @property (strong, nonatomic, readwrite)  NSError   *failureNSError;

    @property (nonatomic)  BOOL  didUserSkipAd;
    @property (nonatomic)  BOOL  didUserClickAd;
    @property (nonatomic)  BOOL  isAdMuted;
    @property (nonatomic)  BOOL  isVideoTagReady;
    @property (nonatomic)  BOOL  didVideoTagFail;

@end




//---------------------------------------------------------- -o--
@implementation ANInstreamVideoAd

#pragma mark - Lifecycle.

//--------------------- -o-
- (id) initWithPlacementId: (NSString *)placementId 
{
ANLogMark();

    self = [super init];
    if (!self)  { return nil; }

    //
    self.didUserSkipAd    = NO;
    self.didUserClickAd   = NO;
    self.isAdMuted        = NO;
    self.isVideoTagReady  = NO;
    self.didVideoTagFail  = NO;

    self.landingPageLoadsInBackground = YES;
    self.opensInNativeBrowser = NO;

    self.placementId = placementId;

    //
    return self;
}
    



//---------------------------------------------------------- -o--
#pragma mark - Instance methods.

//--------------------- -o-
- (BOOL) loadAdWithDelegate: (id<ANInstreamVideoAdLoadDelegate>)loadDelegate;
{
    ANLogMark();

    if (! loadDelegate) {
        ANLogWarn(@"loadDelegate is UNDEFINED.  ANInstreamVideoAdLoadDelegate allows detection of when a video ad is successfully received and loaded.");
    }

    self.loadDelegate = loadDelegate;

    if (! [[ANUniversalAdFetcher alloc] initWithDelegate:self])  {
        ANLogError(@"FAILED TO FETCH video ad.");
        return  NO;
    }

    return  YES;
}


//--------------------- -o-
- (void) playAdWithContainer: (UIView *)adContainer
                withDelegate: (id<ANInstreamVideoAdPlayDelegate>)playDelegate;
{
ANLogMark();

    if (!playDelegate) {
        ANLogError(@"playDelegate is UNDEFINED.  ANInstreamVideoAdPlayDelegate allows the lifecycle of a video ad to be tracked, including when the video ad is completed.");
        return;
    }

    self.playDelegate = playDelegate;

    [self.adPlayer playAdWithContainer:adContainer];
}


//--------------------- -o-
- (void) removeAd
{
ANLogMark();
    if(self.adPlayer != nil){
        [self.adPlayer removePlayer];
        [self.adPlayer removeFromSuperview];
        self.adPlayer = nil;
    }
}



//---------------------------------------------------------- -o--
#pragma mark - ANVideoAdPlayerDelegate.

//--------------------- -o-
-(void) videoAdReady
{
ANLogMark();

    self.isVideoTagReady = YES;

    if ([self.loadDelegate respondsToSelector:@selector(adDidReceiveAd:)]) {
        [self.loadDelegate adDidReceiveAd:self];
    }
}


//--------------------- -o-
-(void) videoAdLoadFailed:(NSError *)error
{
ANLogMark();
    self.didVideoTagFail = YES;

    self.descriptionOfFailure  = nil;
    self.failureNSError        = error;

    ANLogError(@"Delegate indicates FAILURE.");
    [self removeAd];

    if ([self.loadDelegate respondsToSelector:@selector(ad:requestFailedWithError:)]) {
        [self.loadDelegate ad:self requestFailedWithError:self.failureNSError];
    }
}


//--------------------- -o-
-(void) videoAdPlayFailed:(NSError *)error
{
ANLogMark();

    self.didVideoTagFail = YES;

    if ([self.playDelegate respondsToSelector:@selector(adDidComplete:withState:)])  {
        [self.playDelegate adDidComplete:self withState:ANInstreamVideoPlaybackStateError];
    }

    [self removeAd];
}


//--------------------- -o-
- (void) videoAdError:(NSError *)error
{
ANLogMark();
    self.descriptionOfFailure  = nil;
    self.failureNSError        = error;

    if ([self.playDelegate respondsToSelector:@selector(adDidComplete:withState:)]) {
        [self.playDelegate adDidComplete:self withState:ANInstreamVideoPlaybackStateError];
    }
}


//--------------------- -o-
- (void) videoAdWillPresent:(ANVideoAdPlayer *)videoAd
{
ANLogMark();

    if ([self.playDelegate respondsToSelector:@selector(adWillPresent:)]) {
        [self.playDelegate adWillPresent:self];
    }
}


//--------------------- -o-
- (void) videoAdDidPresent:(ANVideoAdPlayer *)videoAd
{
ANLogMark();

    if ([self.playDelegate respondsToSelector:@selector(adDidPresent:)]) {
        [self.playDelegate adDidPresent:self];
    }
}


//--------------------- -o-
- (void) videoAdWillClose:(ANVideoAdPlayer *)videoAd
{
ANLogMark();

    if ([self.playDelegate respondsToSelector:@selector(adWillClose:)]) {
        [self.playDelegate adWillClose:self];
    }
}


//--------------------- -o-
- (void) videoAdDidClose:(ANVideoAdPlayer *)videoAd
{
ANLogMark();

    if ([self.playDelegate respondsToSelector:@selector(adDidClose:)]) {
        [self removeAd];
        [self.playDelegate adDidClose:self];
    }
}


//--------------------- -o-
- (void) videoAdWillLeaveApplication:(ANVideoAdPlayer *)videoAd
{
    if ([self.playDelegate respondsToSelector:@selector(adWillLeaveApplication:)])  {
        [self.playDelegate adWillLeaveApplication:self];
    }
}


//--------------------- -o-
-(void) videoAdImpressionListeners:(ANVideoAdPlayerTracker)tracker
{
//ANLogMark();

    switch (tracker) {
        case ANVideoAdPlayerTrackerFirstQuartile:
            if ([self.playDelegate respondsToSelector:@selector(adCompletedFirstQuartile:)]) {
                [self.playDelegate adCompletedFirstQuartile:self];
            }
            break;
        case ANVideoAdPlayerTrackerMidQuartile:
            if ([self.playDelegate respondsToSelector:@selector(adCompletedMidQuartile:)]) {
                [self.playDelegate adCompletedMidQuartile:self];
            }
            break;
        case ANVideoAdPlayerTrackerThirdQuartile:
            if ([self.playDelegate respondsToSelector:@selector(adCompletedThirdQuartile:)]) {
                [self.playDelegate adCompletedThirdQuartile:self];
            }
            break;
        case ANVideoAdPlayerTrackerFourthQuartile:
            if ([self.playDelegate respondsToSelector:@selector(adDidComplete:withState:)]) {
                [self removeAd];
                [self.playDelegate adDidComplete:self withState:ANInstreamVideoPlaybackStateCompleted];
            }
            break;
        default:
            break;
    }
}


//--------------------- -o-
-(void) videoAdEventListeners:(ANVideoAdPlayerEvent)eventTrackers
{
//ANLogMark();

    switch (eventTrackers) {
        case ANVideoAdPlayerEventSkip:
            self.didUserSkipAd = YES;

            if([self.playDelegate respondsToSelector:@selector(adDidComplete:withState:)]){
                [self.playDelegate adDidComplete:self withState:ANInstreamVideoPlaybackStateSkipped];
            }
            break;

        case ANVideoAdPlayerEventClick:
            self.didUserClickAd = YES;

            if ([self.playDelegate respondsToSelector:@selector(adWasClicked:)])  {
                [self.playDelegate adWasClicked:self];
            }
            break;
        case ANVideoAdPlayerEventMuteOn:
            self.isAdMuted = YES;
            
            if ([self.playDelegate respondsToSelector:@selector(adMute:withStatus:)])  {
                [self.playDelegate adMute:self withStatus:self.isAdMuted];
            }
            break;
        case ANVideoAdPlayerEventMuteOff:
            self.isAdMuted = NO;
            
            if ([self.playDelegate respondsToSelector:@selector(adMute:withStatus:)])  {
                [self.playDelegate adMute:self withStatus:self.isAdMuted];
            }
            break;
        default:
            break;
    }
}


//--------------------- -o-
- (BOOL) videoAdPlayerOpensInNativeBrowser  {
    return  self.opensInNativeBrowser;
}


//--------------------- -o-
- (BOOL) videoAdPlayerLandingPageLoadsInBackground  {
    return  self.landingPageLoadsInBackground;
}




//---------------------------------------------------------- -o--
#pragma mark - ANInstreamVideoAdUniversalFetcherDelegate.

//--------------------- -o-
- (void)       universalAdFetcher: (ANUniversalAdFetcher *)fetcher
     didFinishRequestWithResponse: (ANAdFetcherResponse *)response
{
ANLogMark();
    
    if ([response.adObject isKindOfClass:[ANVideoAdPlayer class]]) {
        
        self.adPlayer = (ANVideoAdPlayer *) response.adObject;
        self.adPlayer.delegate = self;
        [self videoAdReady];
        
    }else if(!response.isSuccessful && (response.adObject == nil)){
        [self videoAdLoadFailed:ANError(@"video_adfetch_failed", ANAdResponseBadFormat)];
        return;
    }
}




//---------------------------------------------------------- -o--
#pragma mark - ANAdViewInternalDelegate.


- (void)adDidReceiveAd
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adRequestFailedWithError:(NSError *)error
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adWasClicked
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adWillPresent
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adDidPresent
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adWillClose
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adDidClose
{
ANLogMarkMessage(@"UNUSED");
}


- (void)adWillLeaveApplication
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adDidReceiveAppEvent:(NSString *)name withData:(NSString *)data
{
ANLogMarkMessage(@"UNUSED");
}

- (NSString *)adType
{
    return  @"instreamVideo";   //XXX
}

- (UIViewController *)displayController
{
ANLogMarkMessage(@"UNUSED");
    return  nil;
}

- (void)adInteractionDidBegin
{
ANLogMarkMessage(@"UNUSED");
}

- (void)adInteractionDidEnd
{
ANLogMarkMessage(@"UNUSED");
}




//---------------------------------------------------------- -o--
#pragma mark - ANAdProtocol.

/** Set the user's current location.  This allows ad buyers to do location targeting, which can increase spend.
 */
- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy];
}


/** Set the user's current location rounded to the number of decimal places specified in "precision".
    Valid values are between 0 and 6 inclusive. If the precision is -1, no rounding will occur.
 */
- (void)setLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                      timestamp:(NSDate *)timestamp horizontalAccuracy:(CGFloat)horizontalAccuracy
                      precision:(NSInteger)precision {
    self.location = [ANLocation getLocationWithLatitude:latitude
                                              longitude:longitude
                                              timestamp:timestamp
                                     horizontalAccuracy:horizontalAccuracy
                                              precision:precision];
}



/**
 These methods add and remove custom keywords to and from the
 customKeywords dictionary.
 */
- (void)addCustomKeywordWithKey:(NSString *)key
                          value:(NSString *)value
{
ANLogMark();

    if (([key length] < 1) || !value) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // ANTargetingParameters still depends on this value
    [self.customKeywords setValue:value forKey:key];
#pragma clang diagnostic pop

    if (self.customKeywordsMap[key] != nil){
        NSMutableArray *valueArray = (NSMutableArray *)[self.customKeywordsMap[key] mutableCopy];
        if (![valueArray containsObject:value]) {
            [valueArray addObject:value];
        }
        self.customKeywordsMap[key] = [valueArray copy];
    } else {
        self.customKeywordsMap[key] = @[value];
    }
}


- (void)removeCustomKeywordWithKey:(NSString *)key
{
ANLogMark();

    if (([key length] < 1)) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // ANTargetingParameters still depends on this value
    [self.customKeywords removeObjectForKey:key];
#pragma clang diagnostic pop

    [self.customKeywordsMap removeObjectForKey:key];
}


- (void)clearCustomKeywords
{
ANLogMark();

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.customKeywords removeAllObjects];
#pragma clang diagnostic pop

    [self.customKeywordsMap removeAllObjects];
}


/**
 Set the inventory code and member id for the place that ads will be shown.
 */
@synthesize  memberId       = _memberId;
@synthesize  inventoryCode  = _inventoryCode;

- (void)setInventoryCode: (NSString *)inventoryCode
                memberId: (NSInteger)memberID
{
    if (inventoryCode && (inventoryCode != _inventoryCode)) {
        ANLogDebug(@"Setting inventory code to %@", inventoryCode);
        _inventoryCode = inventoryCode;
    }
    if ( (memberID > 0) && (memberID != _memberId) ) {
        ANLogDebug(@"Setting member id to %d", (int) memberID);
        _memberId = memberID;
    }
}


@end

