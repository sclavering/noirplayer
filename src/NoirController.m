/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NoirController.h"
#import "NoirDocument.h"

id controller;

@implementation NoirController

+(id) controller {
    return controller;
}

+(void) setController:(id)aNoirController {
    controller = aNoirController;
}

-(void) awakeFromNib {
    lastMouseLocation = NSMakePoint(0, 0);
    mouseMoveTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkMouseLocation:) userInfo:nil repeats:YES]; // Auto-hides mouse.
    lastCursorMoveDate = [[NSDate alloc] init];
    [NoirController setController:self];
    antiSleepTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(preventSleep:) userInfo:nil repeats:YES];
}

-(void) dealloc {
    [mouseMoveTimer invalidate];
    [antiSleepTimer invalidate];
}

-(NSInteger) runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions {
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    return [super runModalOpenPanel:openPanel forTypes:@[
        @"public.movie",
        // This should match the filename extensions declared in Info.plist
        // We should only need to list those that aren't already covered by the public.movie UTI per https://developer.apple.com/library/mac/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
        @"asf",
        @"divx",
        @"flv",
        @"m4v",
        @"mkv",
        @"ogg",
        @"ogm",
        @"webm",
    ]];
}

-(void) checkMouseLocation:(id)sender {
    NSPoint tempPoint =[NSEvent mouseLocation];
    if(!NSEqualPoints(lastMouseLocation, tempPoint)) {
        lastCursorMoveDate = [[NSDate alloc] init];
        lastMouseLocation= tempPoint;
    } else {
        if(lastCursorMoveDate.timeIntervalSinceNow < -3) [NSCursor setHiddenUntilMouseMoves:YES];
    }
}

/* As per Technical Q&A QA1160: http://developer.apple.com/qa/qa2004/qa1160.html */
-(void) preventSleep:(id)sender {
    for(id doc in NSApp.orderedDocuments) {
        if(((NoirDocument*)doc).movie.paused) continue;
        UpdateSystemActivity(OverallAct);
        return;
    }
}

-(IBAction) openDocument:(id)sender {
    NSArray* files = [self URLsFromRunningOpenPanel];
    for(id url in files) {
        NSError* tError = nil;
        [self openDocumentWithContentsOfURL:url display:YES error:&tError];
        if(tError) [NSApp presentError:tError];
    }
}

@end
