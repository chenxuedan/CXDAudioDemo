//
//  CXDAudioButton.h
//  CXDVideoRecord
//
//  Created by CXD on 2020/4/9.
//  Copyright © 2020 cxd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TapEventBlock)(UITapGestureRecognizer *tapGestureRecognizer);

typedef NS_ENUM(NSUInteger, CXDVideoStatus) {
    CXDVideoStatusNormal = 0,   //准备录制状态
    CXDVideoStatusRecording = 1,    //录制状态
    CXDVideoStatusStopRecord = 2, //结束录制状态  处理音频数据
    CXDVideoStatusPlaying = 3,  //播放状态
    CXDVideoStatusStopPlay = 4,  //播放停止状态 准备播放状态
};

@interface CXDAudioButton : UIView

@property (nonatomic, assign) CGFloat progressPercentage;
@property (nonatomic, assign) CXDVideoStatus videoStatus;

+ (instancetype)defaultAudioButton;
- (void)configureTapVideoButtonEventWithBlock:(TapEventBlock)tapEventBlock;

@end

NS_ASSUME_NONNULL_END
