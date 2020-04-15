//
//  CXDAudioButton.m
//  CXDVideoRecord
//
//  Created by CXD on 2020/4/9.
//  Copyright © 2020 cxd. All rights reserved.
//

#import "CXDAudioButton.h"
#import "UIView+CXDAdd.h"
#import "CXDHeaderMacro.h"

//默认按钮大小
#define AUDIOBUTTONWIDTH 120

//录制  红色
#define CXDRecordRedColor RGB(252, 63, 98)
#define CXDPlayBlueColor RGB(23, 185, 290)

@interface CXDAudioButton ()

@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) CAShapeLayer *statusLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, copy) TapEventBlock tapEventBlock;

@end

@implementation CXDAudioButton

+ (instancetype)defaultAudioButton {
    CXDAudioButton *audioButton = [[CXDAudioButton alloc] initWithFrame:CGRectMake(0, 0, AUDIOBUTTONWIDTH, AUDIOBUTTONWIDTH)];
    [audioButton.layer setCornerRadius:AUDIOBUTTONWIDTH/2];
    audioButton.backgroundColor = [UIColor whiteColor];
    [audioButton initCircleLayer];
    [audioButton initNormalLayer];
    return audioButton;
}

- (void)setVideoStatus:(CXDVideoStatus)videoStatus {
    _videoStatus = videoStatus;
    switch (videoStatus) {
        case CXDVideoStatusNormal:  //正常状态
            [self initNormalLayer];
            break;
        case CXDVideoStatusRecording: //正在录制  去暂停按钮 圆角方形
            [self initRecordingPauseLayer];
            break;
        case CXDVideoStatusStopRecord: // 暂停状态  去播放  三角
            [self initPlayingToPlayLayer];
            break;
        case CXDVideoStatusStopPlay:
            [self initPlayingToPlayLayer];
            break;
        case CXDVideoStatusPlaying: //播放状态  进度条
            [self initCircleAnimationLayer];
            break;
        default:
            break;
    }
}

- (void)initCircleLayer {
    float centerX = self.bounds.size.width / 2.0;
    float centerY = self.bounds.size.height / 2.0;
    //半径
    float radius = (self.bounds.size.width) / 2.0;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:(-0.5f * M_PI) endAngle:(1.5f * M_PI) clockwise:YES];
    self.lineLayer = [[CAShapeLayer alloc] init];
    self.lineLayer.frame = self.bounds;
    self.lineLayer.fillColor = [[UIColor clearColor] CGColor];
    self.lineLayer.strokeColor = [RGB(230, 230, 230) CGColor];
    self.lineLayer.lineWidth = 0.7;
    self.lineLayer.path = [path CGPath];
    self.lineLayer.strokeEnd = 1;
    [self.layer addSublayer:self.lineLayer];
}

//初始化录制初态
- (void)initNormalLayer {
    float centerX = self.bounds.size.width / 2.0;
    float centerY = self.bounds.size.height / 2.0;
    //半径
    float radius = (self.bounds.size.width - 20) / 2.0;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:(-0.5f * M_PI) endAngle:(1.5f * M_PI) clockwise:YES];
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    backLayer.frame = self.bounds;
    backLayer.fillColor = [CXDRecordRedColor CGColor];
    backLayer.strokeColor = [[UIColor clearColor] CGColor];
    backLayer.lineWidth = 10;
    backLayer.path = [path CGPath];
    backLayer.strokeEnd = 1;
    self.lineLayer.lineWidth = 0.7;
    [self.statusLayer removeFromSuperlayer];
    self.statusLayer = backLayer;
    [self.layer addSublayer:self.statusLayer];
    _progressLayer.hidden = YES;
}
//录制暂停完成
- (void)initRecordingPauseLayer {
    float centerX = self.bounds.size.width / 2.0;
    float centerY = self.bounds.size.height / 2.0;
    CGFloat width = 50;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(centerX - width / 2, centerY - width / 2, width, width) cornerRadius:8];
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    backLayer.fillColor = [CXDRecordRedColor CGColor];
    backLayer.strokeColor = [RGB(255, 254, 255) CGColor];
    backLayer.path = [path CGPath];
    self.lineLayer.lineWidth = 0.7;
    [self.statusLayer removeFromSuperlayer];
    self.statusLayer = backLayer;
    [self.layer addSublayer:backLayer];
    _progressLayer.hidden = YES;
}

- (void)initPlayingToPlayLayer {
    float centerX = self.bounds.size.width / 2.0;
    float centerY = self.bounds.size.height / 2.0;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path moveToPoint:CGPointMake(centerX + 25, centerY)];
    [path addLineToPoint:CGPointMake(centerX - 15, centerY + 25)];
    [path addLineToPoint:CGPointMake(centerX - 15, centerY - 25)];
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    backLayer.fillColor = [CXDPlayBlueColor CGColor];
    backLayer.strokeColor = [RGB(255, 254, 255) CGColor];
    backLayer.path = [path CGPath];
    self.lineLayer.lineWidth = 3;
    [self.statusLayer removeFromSuperlayer];
    self.statusLayer = backLayer;
    [self.layer addSublayer:backLayer];
    _progressLayer.hidden = YES;
}

//播放
- (void)initCircleAnimationLayer {
    float centerX = self.bounds.size.width / 2.0;
    float centerY = self.bounds.size.height / 2.0;
    CGFloat width = 50;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(centerX - width / 2, centerY - width / 2, width, width) cornerRadius:8];
    CAShapeLayer *backLayer = [CAShapeLayer layer];
    backLayer.fillColor = [CXDPlayBlueColor CGColor];
    backLayer.strokeColor = [RGB(255, 254, 255) CGColor];
    backLayer.path = [path CGPath];
    self.lineLayer.lineWidth = 3;
    [self.statusLayer removeFromSuperlayer];
    self.statusLayer = backLayer;
    [self.layer addSublayer:backLayer];
    
    
    CGFloat lineWidth = 3;
    float radius = (self.bounds.size.width) / 2.0;
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:(-0.5f * M_PI) endAngle:(1.5f * M_PI) clockwise:YES];
    
    _progressLayer = [[CAShapeLayer alloc] init];
    _progressLayer.frame = self.bounds;
    _progressLayer.fillColor = [[UIColor clearColor] CGColor];
    //指定path的渲染颜色
    _progressLayer.strokeColor = [CXDPlayBlueColor CGColor];
    _progressLayer.lineCap = kCALineCapSquare;
    _progressLayer.lineWidth = lineWidth;
    _progressLayer.path = [progressPath CGPath];
    _progressLayer.strokeEnd = 0;
    [self.layer addSublayer:_progressLayer];
    _progressLayer.hidden = NO;
}

- (void)setProgressPercentage:(CGFloat)progressPercentage {
    _progressPercentage = progressPercentage;
    _progressLayer.strokeEnd = progressPercentage;
    [_progressLayer removeAllAnimations];
}

- (void)configureTapVideoButtonEventWithBlock:(TapEventBlock)tapEventBlock {
    self.tapEventBlock = tapEventBlock;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideoButtonEvent:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)tapVideoButtonEvent:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (self.tapEventBlock) {
        self.tapEventBlock(tapGestureRecognizer);
    }
}

@end
