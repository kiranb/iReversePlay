//
//  KBViewController.m
//  iReversePlay
//
//  Created by Kiran on 2/2/13.
//  Copyright (c) 2013 Kiran. All rights reserved.
//

#import "KBViewController.h"

@interface KBViewController ()

- (BOOL)prepareToRecord;
- (BOOL)startRecording;
- (void)stopRecording;
- (BOOL)startAudioSession;
- (BOOL)stopAudioSession;
- (BOOL)startPlaying;
- (void)stopPlaying;
- (void)startPulseEffectOnButton;
- (void)stopPulseEffectOnButton;

@property (strong) AVAudioSession *session;
@property (strong) AVAudioRecorder *recorder;
@property (strong) AVAudioPlayer *player;
@property (strong) NSURL *recordedAudioUrl;
@property (strong) NSURL *flippedAudioUrl;

@property (assign) ePlayerStatusType currentState;

@end


@implementation KBViewController
@synthesize session;
@synthesize recorder;
@synthesize player;
@synthesize recordedAudioUrl;
@synthesize flippedAudioUrl;

@synthesize currentState;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.currentState = eRecordableState;
    
	if ([self startAudioSession])
    {
		[self prepareToRecord];
    }
}


-(IBAction)record:(id)sender
{
    
    switch (self.currentState)
    {
        case eRecordableState:
        {
            self.currentState = eRecordingState;
            [self startRecording];
            [sender setImage:[UIImage imageNamed:@"bt_Stop.png"] forState:UIControlStateNormal];
            [self startPulseEffectOnButton];
        }
        break;
            
        case eRecordingState:
        {
            self.currentState = ePlayableState;
            [self performSelectorInBackground:@selector(stopRecording) withObject:nil];
            [self.maskView setHidden:NO];
            [sender setImage:[UIImage imageNamed:@"bt_Play.png"] forState:UIControlStateNormal];
            [self stopPulseEffectOnButton];
        }
        break;
            
        case ePlayableState:
        {
            self.currentState = ePlayingState;
            [self startPlaying];
            self.textImageView.image = [UIImage imageNamed:@"txt_Playback.png"];
            [sender setImage:[UIImage imageNamed:@"bt_Stop.png"] forState:UIControlStateNormal];
            [self startPulseEffectOnButton];
        }
        break;
            
        case ePlayingState:
        {
            self.currentState = eRecordableState;
            [self stopPlaying];
            [sender setImage:[UIImage imageNamed:@"bt_Record.png"] forState:UIControlStateNormal];
            self.textImageView.image = [UIImage imageNamed:@"txt_ReadMe.png"];
            [self stopPulseEffectOnButton];
        }
        break;
            
        default:
            break;
    }
    
    
}


#pragma mark -
#pragma mark AVAudioPlayerDelegate methods
#pragma mark -

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	NSLog(@"audioPlayerDidFinishPlaying");
    [self.button setImage:[UIImage imageNamed:@"bt_Record.png"] forState:UIControlStateNormal];
    self.textImageView.image = [UIImage imageNamed:@"txt_ReadMe.png"];
    self.currentState = eRecordableState;
    [self stopPulseEffectOnButton];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
	NSLog(@"audioRecorderDidFinishRecording");
    NSLog(@"File saved to %@", [[self.recordedAudioUrl path] lastPathComponent]);
}


#pragma mark -
#pragma mark Private methods
#pragma mark -

- (void) stopRecording
{
	[self.recorder stop];
    
    /*
     As each sample is 16-bits in size(2 bytes)(mono channel).
     You can load each sample at a time by copying it into a different buffer by starting at the end of the recording and
     reading backwards. When you get to the start of the data you have reversed the data and playing will be reversed.
     */
    
    // set up output file
    AudioFileID outputAudioFile;
    
    AudioStreamBasicDescription myPCMFormat;
	myPCMFormat.mSampleRate = 16000.00;
	myPCMFormat.mFormatID = kAudioFormatLinearPCM ;
	myPCMFormat.mFormatFlags =  kAudioFormatFlagsCanonical;
	myPCMFormat.mChannelsPerFrame = 1;
	myPCMFormat.mFramesPerPacket = 1;
	myPCMFormat.mBitsPerChannel = 16;
	myPCMFormat.mBytesPerPacket = 2;
	myPCMFormat.mBytesPerFrame = 2;
    
    
	AudioFileCreateWithURL((__bridge CFURLRef)self.flippedAudioUrl,
                           kAudioFileCAFType,
                           &myPCMFormat,
                           kAudioFileFlags_EraseFile,
                           &outputAudioFile);
    // set up input file
    AudioFileID inputAudioFile;
    OSStatus theErr = noErr;
    UInt64 fileDataSize = 0;
    
    AudioStreamBasicDescription theFileFormat;
    UInt32 thePropertySize = sizeof(theFileFormat);
    
    theErr = AudioFileOpenURL((__bridge CFURLRef)self.recordedAudioUrl, kAudioFileReadPermission, 0, &inputAudioFile);
    
    thePropertySize = sizeof(fileDataSize);
    theErr = AudioFileGetProperty(inputAudioFile, kAudioFilePropertyAudioDataByteCount, &thePropertySize, &fileDataSize);
    
    UInt32 dataSize = fileDataSize;
    void* theData = malloc(dataSize);
    
    //Read data into buffer
    UInt32 readPoint  = dataSize;
    UInt32 writePoint = 0;
    while( readPoint > 0 )
    {
        UInt32 bytesToRead = 2;
        
        AudioFileReadBytes( inputAudioFile, false, readPoint, &bytesToRead, theData );
        AudioFileWriteBytes( outputAudioFile, false, writePoint, &bytesToRead, theData );
        
        writePoint += 2;
        readPoint -= 2;
    }
    
    AudioFileClose(inputAudioFile);
	AudioFileClose(outputAudioFile);
    
    [self.maskView performSelectorOnMainThread:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
}


- (BOOL)startRecording
{
 	if (![self.recorder record])
	{
		NSLog(@"Error: Record failed");
		return NO;
	}
	return TRUE;
}

-(BOOL)prepareToRecord
{
	NSError *error;
	
	// Recording settings
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings setValue: [NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
	[settings setValue: [NSNumber numberWithFloat:16000.00] forKey:AVSampleRateKey];
	[settings setValue: [NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey]; // mono
	[settings setValue: [NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
	[settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
	[settings setValue: [NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
	
	// File URL
    
    NSString *recordPath= [DOCUMENTS_FOLDER stringByAppendingPathComponent:@"test"];
	self.recordedAudioUrl = [[NSURL alloc ] initFileURLWithPath:recordPath];
    
    NSString *flippedPath= [DOCUMENTS_FOLDER stringByAppendingPathComponent:@"result"];
	self.flippedAudioUrl = [[NSURL alloc ] initFileURLWithPath:flippedPath];
	
	// Create recorder
	self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordedAudioUrl settings:settings error:&error];
	if (!self.recorder)
	{
		NSLog(@"Error: %@", [error localizedDescription]);
		return NO;
	}
	
	// Initialize degate, metering, etc.
	self.recorder.delegate = self;
    //	self.recorder.meteringEnabled = YES;
	
	if (![self.recorder prepareToRecord])
	{
		NSLog(@"Error: Prepare to record failed");
		return NO;
	}
    
	return YES;
}


-(BOOL)startPlaying
{
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[DOCUMENTS_FOLDER stringByAppendingPathComponent:@"result"]];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:outputURL error:nil];
    player.delegate = self;
    if(![self.player play])
    {
        NSLog(@"Error: Play failed");
		return NO;
    }
    return YES;
}

-(void)stopPlaying
{
    [self.player stop];
}


- (BOOL) startAudioSession
{
	NSLog(@"startAudioSession");
	// Prepare the audio session
	NSError *error;
	self.session = [AVAudioSession sharedInstance];
	
	if (![self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error])
	{
		NSLog(@"Error: %@", [error localizedDescription]);
		return NO;
	}
	
	if (![self.session setActive:YES error:&error])
	{
		NSLog(@"Error: %@", [error localizedDescription]);
		return NO;
	}
	UInt32 ASRoute = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (ASRoute),
                             &ASRoute
                             );
    
	return self.session.inputIsAvailable;
}

- (BOOL)stopAudioSession
{
	NSLog(@"stopAudioSession");
    NSError *error;
	if (![self.session setActive:NO error:&error])
	{
		NSLog(@"Error: %@", [error localizedDescription]);
		return NO;
	}
	return true;
}

-(void)startPulseEffectOnButton
{
    CABasicAnimation *theAnimation;
    
    //            theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=0.8;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.3];
    [self.button.layer addAnimation:theAnimation forKey:@"animateOpacity"];

}

-(void)stopPulseEffectOnButton
{
    [self.button.layer removeAnimationForKey:  @"animateOpacity"];
}
@end
