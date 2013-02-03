//
//  KBViewController.h
//  iReversePlay
//
//  Created by Kiran on 2/2/13.
//  Copyright (c) 2013 Kiran. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

typedef enum
{
    eRecordableState= 0,
    eRecordingState,
    ePlayableState,
    ePlayingState,
}ePlayerStatusType;

@interface KBViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *textImageView;
@property (weak, nonatomic) IBOutlet UIView *maskView;

-(IBAction)record:(id)sender;

@end
