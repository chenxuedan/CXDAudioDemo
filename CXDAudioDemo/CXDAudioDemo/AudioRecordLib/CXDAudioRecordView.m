//
//  CXDAudioRecordView.m
//  CXDVideoRecord
//
//  Created by CXD on 2020/4/10.
//  Copyright © 2020 cxd. All rights reserved.
//

#import "CXDAudioRecordView.h"
#import "CXDAudioButton.h"
#import <AVFoundation/AVFoundation.h>
#import "CXDTimer.h"
#import "lame.h"
#import "UIView+CXDAdd.h"
#import "CXDHeaderMacro.h"

#define AUDIO_RECORDER_MAX_TIME 60

@interface CXDAudioRecordView () <AVAudioPlayerDelegate>

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UILabel *timerLabel;
@property (nonatomic, strong) CXDAudioButton *audioButton;
@property (nonatomic, strong) CALayer *lineLayer;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, copy) NSString *curCafFilePath;
@property (nonatomic, copy) NSString *mp3FilePath;

//计时器
@property (nonatomic, strong) CXDTimer *timer;
//当前录制状态设置
@property (nonatomic, assign) NSUInteger currentStatus;

@property (nonatomic, assign) NSUInteger countDown;
@property (nonatomic, assign) NSUInteger audioDuration;

@property (nonatomic, assign) BOOL isStartRecord;
@property (nonatomic, strong) UIViewController *superVC;

@end

@implementation CXDAudioRecordView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)showWithController:(UIViewController *)controller {
    self.superVC = controller;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupDefaultSetting];
                [[UIApplication sharedApplication].keyWindow addSubview:self];
            });
        } else {
            NSLog(@"提示框");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNoPermissionAlert];
            });
        }
    }];
}

- (void)setupUI {
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    [self addSubview:self.backView];
    [self.backView addSubview:self.timerLabel];
    [self.backView addSubview:self.audioButton];
    [self.backView.layer addSublayer:self.lineLayer];
    [self.backView addSubview:self.cancelButton];
    [self.backView addSubview:self.sendButton];
    [self setupUIContraints];
    [self handleActionEvent];
}

- (void)setupDefaultSetting {
    [self.audioButton setVideoStatus:CXDVideoStatusRecording];
    self.currentStatus = CXDVideoStatusRecording;
    [self startAudioRecord];
}

//事件处理
- (void)handleActionEvent {
    __weak typeof(self) weakSelf = self;
    [self.audioButton configureTapVideoButtonEventWithBlock:^(UITapGestureRecognizer * _Nonnull tapGestureRecognizer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.currentStatus == CXDVideoStatusStopPlay) {
            strongSelf.currentStatus = CXDVideoStatusPlaying;
        } else {
            ++strongSelf.currentStatus;
        }
        [strongSelf resetUIDisplayAndRecord];
    }];
}

- (void)resetUIDisplayAndRecord {
    [self.audioButton setVideoStatus:self.currentStatus];
    switch (self.currentStatus) {  //当前状态
        case CXDVideoStatusRecording:
            [self startAudioRecord];
            break;
        case CXDVideoStatusStopRecord:
            [self stopAudioRecord];
            break;
        case CXDVideoStatusPlaying:
            [self playAudio];
            break;
        case CXDVideoStatusStopPlay:
            [self stopAudioPlay];
            break;
    }
}

- (void)playAudio {
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.mp3FilePath] error:nil];
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    [self startTimer];
}

- (void)stopAudioPlay {
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer stop];
        [self.audioButton setVideoStatus:CXDVideoStatusStopRecord];
        self.currentStatus = CXDVideoStatusStopRecord;
        self.timerLabel.text = [NSString stringWithFormat:@"0:%.2ld",self.audioDuration];
        [self stopTimer];
    }
}

//开始录制
- (void)startAudioRecord {
    self.lineLayer.hidden = YES;
    self.cancelButton.hidden = YES;
    self.sendButton.hidden = YES;
    self.isStartRecord = YES;
    __weak typeof(self) weakSelf = self;
    [self requestRecordingPermission:^(BOOL granted) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (granted) {
            [strongSelf setUpAudioSession];
            [strongSelf startTimer];
        } else {
            [strongSelf showNoPermissionAlert];
        }
    }];
}
//暂停录制
- (void)stopAudioRecord {
    if (_countDown < 1) { //录制不可过短
        return;
    }
    self.timerLabel.text = [NSString stringWithFormat:@"0:%.2ld",self.countDown];
    self.audioDuration = self.countDown;
    self.isStartRecord = NO;
    self.lineLayer.hidden = NO;
    self.cancelButton.hidden = NO;
    self.sendButton.hidden = NO;
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        [self stopTimer];
        self.mp3FilePath = [self audio_PCMtoMP3WithFilePath:self.curCafFilePath];
    }
}

//开启计时器
- (void)startTimer {
    self.countDown = 0;
    CGFloat interval = 1.0f;
    if (!self.isStartRecord) {
        interval = 0.01f;
    }
    self.timer = [CXDTimer timerWithTimeInterval:interval target:self selector:@selector(refreshTimerLabel) repeats:YES];
    [self.timer fire];
}
//刷新时间
- (void)refreshTimerLabel {
    if (self.isStartRecord) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timerLabel.text = [NSString stringWithFormat:@"0:%.2ld/0:%d",++self.countDown,AUDIO_RECORDER_MAX_TIME];
            if (self.countDown >= AUDIO_RECORDER_MAX_TIME) {
                [self stopAudioRecord];
                [self.audioButton setVideoStatus:CXDVideoStatusStopRecord];
                self.currentStatus = CXDVideoStatusStopRecord;
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            ++self.countDown;
            self.timerLabel.text = [NSString stringWithFormat:@"0:%.2ld",self.countDown/100];
            if (self.countDown >= self.audioDuration * 100) {
                [self.audioButton setVideoStatus:CXDVideoStatusStopRecord];
                self.currentStatus = CXDVideoStatusStopRecord;
                [self.audioButton setProgressPercentage:1];
                [self stopTimer];
            } else {
                [self.audioButton setProgressPercentage:(self.audioPlayer.currentTime / self.audioPlayer.duration)];
            }
        });
    }
}
//通知计时器
- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

//配置音频会话
- (void)setUpAudioSession {
    self.audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&setCategoryError];
    if (setCategoryError) {
        NSLog(@"%@", setCategoryError.localizedDescription);
    }
    [self.audioSession setActive:YES error:nil];
    
    NSString *audioFilePath = [self generateAudioFilePathWithDate:[NSDate date] andExt:@"caf"];
    self.curCafFilePath = audioFilePath;
    NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
    //录音通道数  1 或 2 ，要转换成mp3格式必须为双通道
    //kAudioFormatMPEGLayer3 设置为MP3会导致audioRecorder无法初始化
    ////设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）, 采样率必须要设为11025才能使转化成mp3格式后不会失真
    NSDictionary *recordSetting = @{
                                    AVSampleRateKey: @11025.0f,                         // 采样率
                                    AVFormatIDKey: @(kAudioFormatLinearPCM),           // 音频格式
                                    AVLinearPCMBitDepthKey: @16,                       // 采样位数
                                    AVNumberOfChannelsKey: @2,                         // 音频通道
                                    AVEncoderAudioQualityKey: @(AVAudioQualityLow)    // 录音质量
    };
    NSError *recorderError = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:audioFileUrl settings:recordSetting error:&recorderError];
    if (recorderError) {
        //OSStatus错误1718449215。 kAudioFormatMPEGLayer3
        NSLog(@"录制器初始化  %@",recorderError.localizedDescription);
    }
    self.audioRecorder.meteringEnabled = YES;
    [self.audioRecorder prepareToRecord];
    [self.audioRecorder record];
}
//获取音频权限
- (void)requestRecordingPermission:(void (^)(BOOL))callback {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted){
            callback(granted);
        }];
    }
}
//无权限下，提示框
- (void)showNoPermissionAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无权限" message:@"请在设置中打开权限" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:alertAction];
    [self.superVC presentViewController:alertController animated:YES completion:nil];
}

//取消
- (void)cancelButtonAction {
    if (self.mp3FilePath) {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:self.mp3FilePath] error:nil];
    }
    [self stopAudioPlay];
    [self stopTimer];
    [self removeFromSuperview];
}

//发送
- (void)sendButtonAction {
    [self stopAudioPlay];
    [self stopTimer];
    if (self.audioCompletionBlock) {
        self.audioCompletionBlock(self.mp3FilePath);
    }
    [self removeFromSuperview];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
}

- (NSString *)audio_PCMtoMP3WithFilePath:(NSString *)filePath {
    NSString *cafFilePath = filePath;    //caf文件路径
    NSString *mp3FileName = [self generateAudioFilePathWithDate:[NSDate date] andExt:@"mp3"];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FileName cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame, 2);//设置1为单通道，默认为2双通道
        lame_set_in_samplerate(lame, 11025.0);//11025.0        8000.0
        //        lame_set_VBR(lame, vbr_default);
        lame_set_brate(lame, 16);
        lame_set_mode(lame, 3);
        lame_set_quality(lame, 2);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
//        self.audioFileSavePath = mp3FilePath;
//        NSLog(@"MP3生成成功: %@",mp3FileName);
    }
    return mp3FileName;
}

#pragma mark - 私有方法
//生成音频文件路径地址
- (NSString *)generateAudioFilePathWithDate:(NSDate *)date andExt:(NSString *)ext {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
       [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
       NSString *dateString = [formatter stringFromDate:date];
    NSString *directoryPath = [self getAudioDirectoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.%@",directoryPath,dateString,ext];
    return filePath;
}

- (NSString *)getAudioDirectoryPath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *directoryPath = [NSString stringWithFormat:@"%@/soundFile",cachePath];
    return directoryPath;
}

//UI约束
- (void)setupUIContraints {
//    __weak typeof(self) weakSelf = self;
    CGFloat backHeight = 300 + CXDTabBarMargin;
    self.backView.frame = CGRectMake(0, kScreenHeight - backHeight, kScreenWidth, backHeight);
    self.timerLabel.frame = CGRectMake(20, 20, kScreenWidth - 40, 20);
    self.audioButton.frame = CGRectMake(0, 55, 120, 120);
    self.audioButton.centerX = self.backView.centerX;
//    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.right.bottom.mas_equalTo(weakSelf);
//        make.height.mas_equalTo(backHeight);
//    }];
//    [self.timerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(weakSelf.backView.mas_top).mas_offset(20);
//        make.centerX.mas_equalTo(weakSelf.backView.mas_centerX);
//    }];
//    [self.audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(weakSelf.timerLabel.mas_bottom).mas_offset(15);
//        make.centerX.mas_equalTo(weakSelf.backView.mas_centerX);
//        make.size.mas_equalTo(CGSizeMake(120, 120));
//    }];
//    CGFloat width = self.width/2;
//    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.mas_equalTo(0);
//        make.bottom.mas_equalTo(-CXDTabBarMargin);
//        make.size.mas_equalTo(CGSizeMake(width, 49));
//    }];
//    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.right.mas_equalTo(0);
//        make.bottom.mas_equalTo(weakSelf.cancelButton);
//        make.size.mas_equalTo(CGSizeMake(width, 49));
//    }];
    _lineLayer.frame = CGRectMake(0, backHeight - 55 - CXDTabBarMargin, self.bounds.size.width, 0.6);
    self.cancelButton.frame = CGRectMake(0, backHeight - 54 - CXDTabBarMargin, kScreenWidth / 2, 49);
    self.sendButton.frame = CGRectMake(kScreenWidth / 2, backHeight - 54 - CXDTabBarMargin, kScreenWidth / 2, 49);
}

#pragma mark - Lazy Loading
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectZero];
        _backView.backgroundColor = [UIColor whiteColor];
    }
    return _backView;
}

- (UILabel *)timerLabel {
    if (!_timerLabel) {
        _timerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timerLabel.font = [UIFont systemFontOfSize:16];
        _timerLabel.textColor = CXDTitleColor;
        _timerLabel.text = @"00:00";
        _timerLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _timerLabel;
}

- (CXDAudioButton *)audioButton {
    if (!_audioButton) {
        _audioButton = [CXDAudioButton defaultAudioButton];
    }
    return _audioButton;
}

- (CALayer *)lineLayer {
    if (!_lineLayer) {
        _lineLayer = [[CALayer alloc] init];
        _lineLayer.backgroundColor = CXDHomeLineColor.CGColor;
    }
    return _lineLayer;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_cancelButton setTitleColor:RGB(23, 185, 290) forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_sendButton setTitleColor:RGB(23, 185, 290) forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

@end
