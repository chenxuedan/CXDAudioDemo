//
//  CXDAudioRecordView.h
//  CXDVideoRecord
//
//  Created by CXD on 2020/4/10.
//  Copyright © 2020 cxd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AudioRecordCompletionBlock)(NSString *audioFileString);

@interface CXDAudioRecordView : UIView

@property (nonatomic, copy) AudioRecordCompletionBlock audioCompletionBlock;
- (void)showWithController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
