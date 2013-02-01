//
//  KBViewController.m
//  RecordndPlay
//
//  Created by Kiran B on 30/1/13.
//  Copyright (c) 2013 Kiran B. All rights reserved.
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

@property (strong) AVAudioSession *session;
@property (strong) AVAudioRecorder *recorder;
@property (strong) AVAudioPlayer *player;
@property (strong) NSURL *recordedAudioUrl;
@property (strong) NSURL *flippedAudioUrl;

@property (assign) ePlayerStatusType previousState;
@property (assign) ePlayerStatusType currentState;

@property (assign) BOOL isAudioRecorded;
@end


@implementation KBViewController
@synthesize session;
@synthesize recorder;
@synthesize player;
@synthesize recordedAudioUrl;
@synthesize flippedAudioUrl;

@synthesize previousState;
@synthesize currentState;
@synthesize isAudioRecorded;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
	if ([self startAudioSession])
    {
		[self prepareToRecord];
    }
}


-(IBAction)record:(id)sender
{
    if(NO == self.isAudioRecorded && ![sender isSelected])
    {
        [self startRecording];
    }
    else if(YES == self.isAudioRecorded && ![sender isSelected])
    {
        [self startPlaying];
    }
    [sender setSelected:YES];
    [sender addTarget:self
               action:@selector(stop:)
       forControlEvents:UIControlEventTouchUpInside];

}

-(IBAction)stop:(id)sender
{
    if(NO == self.isAudioRecorded && [sender isSelected])
    {
        [self stopRecording];
        
        [sender setImage:[UIImage imageNamed:@"bt_Play.png"] forState:UIControlStateNormal];
    }
    else if(YES == self.isAudioRecorded && [sender isSelected])
    {
        [self stopPlaying];
        [sender setImage:[UIImage imageNamed:@"bt_Record.png"] forState:UIControlStateNormal];

    }
    [sender setSelected:NO];
    [sender addTarget:self
               action:@selector(record:)
     forControlEvents:UIControlEventTouchUpInside];
}





#pragma mark -
#pragma mark AVAudioPlayerDelegate methods
#pragma mark -

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	NSLog(@"audioPlayerDidFinishPlaying");
    self.button.selected = NO;
    [self.button setImage:[UIImage imageNamed:@"bt_Record.png"] forState:UIControlStateNormal];
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
    
    self.isAudioRecorded = YES;
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
    self.isAudioRecorded = NO;
    [self.player stop];
}


- (BOOL) startAudioSession
{
	NSLog(@"startAudioSession");
	// Prepare the audio session
	NSError *error;
    self.isAudioRecorded = NO;
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


@end
