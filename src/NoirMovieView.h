/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Cocoa;
#import <QTKit/QTKit.h>

@class NoirWindow;
@class NoirDocument;

@interface NoirMovieView : NSView {
    QTMovie* movie;
    QTMovieLayer* qtlayer;
}

-(void)openMovie:(QTMovie*)movie;
-(void)close;

@end
