/* 
   GSPasteboardServer.h

   Copyright (C) 1997,1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: August 1997
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_GSPasteboardServer
#define _GNUstep_H_GSPasteboardServer

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <AppKit/NSPasteboard.h>

@class NSString;
@class NSArray;
@class NSData;

/*
 *	The name of the pasteboard server.
 */
#define	PBSNAME	@"GNUstepGSPasteboardServer"

/*
 *	This protocol for use in asking GSPasteboardObj on the server to
 *	perform tasks for the local NSPasteboard objects.
 */
@protocol GSPasteboardObj
- (int) addTypes: (in bycopy NSArray*)types
	   owner: (id)owner
      pasteboard: (NSPasteboard*)pb
        oldCount: (int)count;
- (NSString*) availableTypeFromArray: (in bycopy NSArray*)types
			 changeCount: (int*)count;
- (int) changeCount;
- (NSData*) dataForType: (in bycopy NSString*)type
	       oldCount: (int)count
          mustBeCurrent: (BOOL)flag;
- (int) declareTypes: (in bycopy NSArray*)types
	       owner: (id)owner
          pasteboard: (NSPasteboard*)pb;
- (NSString*) name;
- (void) releaseGlobally;
- (BOOL) setData: (in bycopy NSData*)data
         forType: (in bycopy NSString*)type
          isFile: (BOOL)flag
        oldCount: (int)count;
- (void) setHistory: (unsigned)length;
- (bycopy NSArray*) typesAndChangeCount: (int*)count;
@end

/*
 *	This protocol for use in obtaining GSPasteboardObj from the server
 *	and controlling general server behaviour.
 */
@protocol GSPasteboardSvr
- (id<GSPasteboardObj>) pasteboardWithName: (in bycopy NSString*)name;
@end

/*
 *	This protocol is used by the server to ask pasteboard clients to
 *	provide additional data.
 */
@protocol GSPasteboardCallback
- (void) pasteboard: (NSPasteboard*)pb
 provideDataForType: (NSString*)type;
- (void) pasteboard: (NSPasteboard*)pb
 provideDataForType: (NSString*)type
	 andVersion:(int)v;
- (void) pasteboardChangedOwner: (NSPasteboard*)pb;
@end

#endif // _GNUstep_H_GSPasteboardServer
