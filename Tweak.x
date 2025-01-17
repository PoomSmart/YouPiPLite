#import "Header.h"
#import <YouTubeHeader/MLPIPController.h>
#import <YouTubeHeader/YTBackgroundabilityPolicy.h>
#import <YouTubeHeader/YTBackgroundabilityPolicyImpl.h>
#import <YouTubeHeader/YTPlayerPIPController.h>

static void activatePiPBase(YTPlayerPIPController *controller) {
    MLPIPController *pip = [controller valueForKey:@"_pipController"];
    if ([controller respondsToSelector:@selector(maybeEnablePictureInPicture)])
        [controller maybeEnablePictureInPicture];
    else if ([controller respondsToSelector:@selector(maybeInvokePictureInPicture)])
        [controller maybeInvokePictureInPicture];
    else {
        BOOL canPiP = [controller respondsToSelector:@selector(canEnablePictureInPicture)] && [controller canEnablePictureInPicture];
        if (!canPiP)
            canPiP = [controller respondsToSelector:@selector(canInvokePictureInPicture)] && [controller canInvokePictureInPicture];
        if (canPiP) {
            if ([pip respondsToSelector:@selector(activatePiPController)])
                [pip activatePiPController];
            else
                [pip startPictureInPicture];
        }
    }
    AVPictureInPictureController *avpip = [pip valueForKey:@"_pictureInPictureController"];
    if ([avpip isPictureInPicturePossible])
        [avpip startPictureInPicture];
}

#pragma mark - PiP Support

%hook AVPictureInPictureController

+ (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook AVPlayerController

- (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook MLPIPController

- (BOOL)isPictureInPictureSupported {
    return YES;
}

%end

%hook YTIIosMediaHotConfig

%new(c@:)
- (BOOL)enablePictureInPicture {
    return YES;
}

%new(c@:)
- (BOOL)enablePipForNonPremiumUsers {
    return YES;
}

%end

#pragma mark - PiP Support, Backgroundable

%hook YTBackgroundabilityPolicy

- (void)updateIsBackgroundableByUserSettings {
    %orig;
    [self setValue:@(YES) forKey:@"_backgroundableByUserSettings"];
}

- (void)updateIsPictureInPicturePlayableByUserSettings {
    %orig;
    [self setValue:@(YES) forKey:@"_playableInPiPByUserSettings"];
}

%end

%hook YTBackgroundabilityPolicyImpl

- (void)updateIsBackgroundableByUserSettings {
    %orig;
    [self setValue:@(YES) forKey:@"_backgroundableByUserSettings"];
}

- (void)updateIsPictureInPicturePlayableByUserSettings {
    %orig;
    [self setValue:@(YES) forKey:@"_playableInPiPByUserSettings"];
}

%end

#pragma mark - Hacks

BOOL YTSingleVideo_isLivePlayback_override = NO;

%hook YTSingleVideo

- (BOOL)isLivePlayback {
    return YTSingleVideo_isLivePlayback_override ? NO : %orig;
}

%end

%hook YTPlayerPIPController

- (BOOL)canInvokePictureInPicture {
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (BOOL)canEnablePictureInPicture {
    YTSingleVideo_isLivePlayback_override = YES;
    BOOL value = %orig;
    YTSingleVideo_isLivePlayback_override = NO;
    return value;
}

- (void)appWillResignActive:(id)arg1 {
    activatePiPBase(self);
    %orig;
}

%end

%hook YTIPlayabilityStatus

- (BOOL)isPlayableInPictureInPicture {
    return YES;
}

- (BOOL)hasPictureInPicture {
    return YES;
}

%end
