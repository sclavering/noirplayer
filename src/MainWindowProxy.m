/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MainWindowProxy.h"


@implementation MainWindowProxy

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id friend = [NSApp.delegate documentForWindow:NSApp.mainWindow];
    if ([friend respondsToSelector:invocation.selector])
        [invocation invokeWithTarget:friend];
    else
        [self doesNotRecognizeSelector:invocation.selector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
  return [NSWindow instanceMethodSignatureForSelector:aSelector];
}
@end
