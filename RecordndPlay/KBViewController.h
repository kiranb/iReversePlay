//
//  KBViewController.h
//  RecordndPlay
//
//  Created by Kiran B on 30/1/13.
//  Copyright (c) 2013 Kiran B. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

typedef enum
{
    eInitial = 0,
    eRecord,
    eStop,
    ePlay,
}ePlayerStatusType;

@interface KBViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *button;

-(IBAction)record:(id)sender;
-(IBAction)stop:(id)sender;

@end
