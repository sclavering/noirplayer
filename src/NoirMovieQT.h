/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import QTKit;

@interface NoirMovieQT : NSObject
{
    QTMovie* _qtmovie;
}

-(instancetype)initWithURL:(NSURL*)url error:(NSError**)outError;

-(CALayer*)getRenderingLayer;
-(void)close;

-(BOOL)isPlaying;
-(void)play;
-(void)pause;

-(double)percentLoaded;
-(NSSize)naturalSize;

-(double)totalTime;
@property (nonatomic, getter=currentTime, setter=setCurrentTime:) double currentTime;

-(float)volume;
-(void)setVolume:(float)val;

-(NSMenu*)audioTrackMenu;
-(NSMenu*)videoTrackMenu;

@end
