//
//  CXDBaseViewController.m
//  CXDAudioDemo
//
//  Created by ZXY on 2020/4/15.
//  Copyright © 2020 cxd. All rights reserved.
//

#import "CXDBaseViewController.h"
#import "CXDAudioRecordView.h"
#import "CXDAudioButton.h"

@interface CXDBaseViewController ()

@property (nonatomic, strong) CXDAudioButton *audioButton;

@end

@implementation CXDBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.audioButton];
    __weak typeof(self) weakSelf = self;
    [self.audioButton configureTapVideoButtonEventWithBlock:^(UITapGestureRecognizer * _Nonnull tapGestureRecognizer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
            CXDAudioRecordView *recordView = [[CXDAudioRecordView alloc] init];
        recordView.audioCompletionBlock = ^(NSString * _Nonnull audioFileString) {
            NSLog(@"音频地址：   %@",audioFileString);
        };
            [recordView showWithController:strongSelf];
        }];
}

- (CXDAudioButton *)audioButton {
    if (!_audioButton) {
        _audioButton = [CXDAudioButton defaultAudioButton];
        _audioButton.frame = CGRectMake(60, 200, 120, 120);
    }
    return _audioButton;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
