/* Copyright 2015 APPNEXUS INC
 
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

#define interstitial [[[UIApplication sharedApplication] keyWindow] accessibilityElementWithLabel:@"interstitial"]
#define player [[[UIApplication sharedApplication] keyWindow] accessibilityElementWithLabel:@"player"]

#import "VolumeClickTest.h"
#import <KIF/KIFTestCase.h>
#import "ANInterstitialAd.h"

@interface VolumeClickTest()<ANVideoAdDelegate, ANInterstitialAdDelegate>{
    ANInterstitialAd *interstitialAdView;
}

@end

@implementation VolumeClickTest

static dispatch_semaphore_t waitForVolumeButtonToBeClicked;
static BOOL isVolumeButtonClicked;

- (void)setUp{
    [super setUp];
    
    isVolumeButtonClicked = NO;
}

- (void)tearDown{
    [super tearDown];
}

- (void)test1PrepareForVolumeTesting{
    [tester waitForViewWithAccessibilityLabel:@"interstitial"];
    [self setupDelegatesForVideo];

    int breakCounter = 5;
    
    while (interstitial && breakCounter--) {
        [self performClickOnInterstitial];
        [tester waitForTimeInterval:3.0];
    }
    

    if (!interstitial) {
        [tester waitForViewWithAccessibilityLabel:@"player"];
        if (!player) {
            NSLog(@"Test: Not able to load the video.");
        }
    }
    
    XCTAssertNil(interstitial, @"Failed to load video.");
}

- (void) test2UnmuteVolume{
    
    XCTAssertNil(interstitial, @"Failed to load video.");
 
    waitForVolumeButtonToBeClicked = dispatch_semaphore_create(0);
    
    [self tapOnVolumeButton];

    dispatch_semaphore_wait(waitForVolumeButtonToBeClicked, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    
    XCTAssertTrue(isVolumeButtonClicked, @"failed");
}

- (void) tapOnVolumeButton{
    [tester tapViewWithAccessibilityLabel:@"volume button"];
}

- (void) test3MuteVolume{

    XCTAssertNil(interstitial, @"Failed to load video.");
    
    waitForVolumeButtonToBeClicked = dispatch_semaphore_create(1);
    
    [self tapOnVolumeButton];
    
    dispatch_semaphore_wait(waitForVolumeButtonToBeClicked, dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_SEC));
    
    XCTAssertTrue(isVolumeButtonClicked, @"failed.");

}

-(void) setupDelegatesForVideo{
    
    UIViewController *controller = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (controller) {
        SEL aSelector = NSSelectorFromString(@"interstitialAd");
        interstitialAdView = (ANInterstitialAd *)[controller performSelector:aSelector];
        interstitialAdView.delegate = self;
        interstitialAdView.videoAdDelegate = self;
    }
}

- (void) performClickOnInterstitial{
    if (interstitial) {
        [tester tapViewWithAccessibilityLabel:@"interstitial"];
    }
}

- (void)adMuted:(BOOL)isMuted withAd:(id<ANAdProtocol>)ad{
    NSLog(@"Test: Ad was %@", isMuted?@"Muted":@"Unmuted");
    isVolumeButtonClicked = YES;
    dispatch_semaphore_signal(waitForVolumeButtonToBeClicked);
}

- (void)adDidReceiveAd:(id<ANAdProtocol>)ad{
    NSLog(@"Test: ad receive ad");
}

- (void)ad:(id<ANAdProtocol>)ad requestFailedWithError:(NSError *)error{
    NSLog(@"Test: request failed with error.");
}

@end
