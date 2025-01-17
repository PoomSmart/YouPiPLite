#import "Header.h"
#import <YouTubeHeader/MLAVPlayer.h>
#import <YouTubeHeader/MLDefaultPlayerViewFactory.h>
#import <YouTubeHeader/MLPIPController.h>
#import <YouTubeHeader/MLPlayerPool.h>
#import <YouTubeHeader/MLPlayerPoolImpl.h>
#import <YouTubeHeader/MLVideoDecoderFactory.h>
#import <YouTubeHeader/YTBackgroundabilityPolicy.h>
#import <YouTubeHeader/YTHotConfig.h>
#import <YouTubeHeader/YTPlayerPIPController.h>

static void forceRenderViewTypeBase(YTIHamplayerConfig *hamplayerConfig) {
    hamplayerConfig.renderViewType = 2;
}

static void forceRenderViewTypeHot(YTIHamplayerHotConfig *hamplayerHotConfig) {
    hamplayerHotConfig.renderViewType = 2;
}

static void forceRenderViewType(YTHotConfig *hotConfig) {
    YTIHamplayerHotConfig *hamplayerHotConfig = [hotConfig hamplayerHotConfig];
    forceRenderViewTypeHot(hamplayerHotConfig);
}

static MLAVPlayer *makeAVPlayer(id self, MLVideo *video, MLInnerTubePlayerConfig *playerConfig, MLPlayerStickySettings *stickySettings, BOOL gimmeAlloc) {
    BOOL externalPlaybackActive = [(MLAVPlayer *)[self valueForKey:@"_activePlayer"] externalPlaybackActive];
    MLAVPlayer *player = gimmeAlloc ? [((MLPlayerPool *)self).gimme allocOf:%c(MLAVPlayer)] : [%c(MLAVPlayer) alloc];
    player = [player initWithVideo:video playerConfig:playerConfig stickySettings:stickySettings externalPlaybackActive:externalPlaybackActive];
    if (stickySettings)
        player.rate = stickySettings.rate;
    return player;
}

%hook MLPIPController

- (void)activatePiPController {
    if ([self pictureInPictureActive]) return;
    AVPictureInPictureController *pip = [self valueForKey:@"_pictureInPictureController"];
    if (pip) return;
    MLAVPIPPlayerLayerView *avpip = [self valueForKey:@"_AVPlayerView"];
    AVPlayerLayer *playerLayer = [avpip playerLayer];
    pip = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
    [self setValue:pip forKey:@"_pictureInPictureController"];
    pip.delegate = self;
}

- (void)deactivatePiPController {
    AVPictureInPictureController *pip = [self valueForKey:@"_pictureInPictureController"];
    [pip stopPictureInPicture];
}

%end

%hook MLPlayerPoolImpl

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings {
    return makeAVPlayer(self, video, playerConfig, stickySettings, NO);
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger {
    return makeAVPlayer(self, video, playerConfig, stickySettings, NO);
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger reloadContext:(id)reloadContext {
    return makeAVPlayer(self, video, playerConfig, stickySettings, NO);
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger reloadContext:(id)reloadContext mediaPlayerResources:(id)mediaPlayerResources {
    return makeAVPlayer(self, video, playerConfig, stickySettings, NO);
}

- (MLAVPlayerLayerView *)playerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    MLDefaultPlayerViewFactory *factory = [self valueForKey:@"_playerViewFactory"];
    return [factory AVPlayerViewForVideo:video playerConfig:playerConfig];
}

- (MLAVPlayerLayerView *)playerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig mediaPlayerResources:(id)mediaPlayerResources {
    MLDefaultPlayerViewFactory *factory = [self valueForKey:@"_playerViewFactory"];
    return [factory AVPlayerViewForVideo:video playerConfig:playerConfig];
}

- (BOOL)canQueuePlayerPlayVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    return NO;
}

- (BOOL)canQueuePlayerPlayVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig reloadContext:(id)reloadContext {
    return NO;
}

%end

%hook MLPlayerPool

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings {
    return makeAVPlayer(self, video, playerConfig, stickySettings, YES);
}

- (id)acquirePlayerForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig stickySettings:(MLPlayerStickySettings *)stickySettings latencyLogger:(id)latencyLogger {
    return makeAVPlayer(self, video, playerConfig, stickySettings, YES);
}

- (MLAVPlayerLayerView *)playerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    MLDefaultPlayerViewFactory *factory = [self valueForKey:@"_playerViewFactory"];
    return [factory AVPlayerViewForVideo:video playerConfig:playerConfig];
}

- (BOOL)canUsePlayerView:(id)playerView forVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forceRenderViewTypeBase([playerConfig hamplayerConfig]);
    return %orig;
}

- (BOOL)canQueuePlayerPlayVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    return NO;
}

%end

%hook MLDefaultPlayerViewFactory

- (id)hamPlayerViewForVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forceRenderViewType([self valueForKey:@"_hotConfig"]);
    forceRenderViewTypeBase([playerConfig hamplayerConfig]);
    return %orig;
}

- (BOOL)canUsePlayerView:(id)playerView forVideo:(MLVideo *)video playerConfig:(MLInnerTubePlayerConfig *)playerConfig {
    forceRenderViewTypeBase([playerConfig hamplayerConfig]);
    return %orig;
}

%end

%hook MLVideoDecoderFactory

- (void)prepareDecoderForFormatDescription:(id)formatDescription delegateQueue:(id)delegateQueue {
    forceRenderViewTypeHot([self valueForKey:@"_hotConfig"]);
    %orig;
}

- (void)prepareDecoderForFormatDescription:(id)formatDescription setPixelBufferTypeOnlyIfEmpty:(BOOL)setPixelBufferTypeOnlyIfEmpty delegateQueue:(id)delegateQueue {
    forceRenderViewTypeHot([self valueForKey:@"_hotConfig"]);
    %orig;
}

%end
