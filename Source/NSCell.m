/*
   NSCell.m

   The abstract cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Modifications:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Rewrite:  Multiple authors
   Date: 1999

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

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>

#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSView.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSColor.h>
#include <AppKit/PSOperators.h>


static	NSColor	*bgCol;
static	NSColor	*hbgCol;
static	NSColor	*txtCol;
static	NSColor	*dtxtCol;
static	NSColor	*clearCol = nil;


@implementation NSCell

static Class	imageClass;
static Class	cellClass;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSCell class])
    {
      [self setVersion: 1];
      imageClass = [NSImage class];
      cellClass = [NSCell class];
    }
}

+ (BOOL) prefersTrackingUntilMouseUp
{
  return NO;
}

/*
 * Instance methods
 */
- _init
{
  cell_type = NSNullCellType;
  cell_image = nil;
  cell_font = nil;
  image_position = NSNoImage;
  cell_state = NO;
  cell_highlighted = NO;
  cell_enabled = YES;
  cell_editable = NO;
  cell_bordered = NO;
  cell_bezeled = NO;
  cell_scrollable = NO;
  cell_selectable = NO;
  cell_continuous = NO;
  cell_float_autorange = NO;
  cell_float_left = 0;
  cell_float_right = 0;
  action_mask = NSLeftMouseUpMask;

  if (clearCol == nil)
    {
      bgCol = RETAIN([NSColor controlBackgroundColor]);
      hbgCol = RETAIN([NSColor selectedControlColor]);
      txtCol = RETAIN([NSColor controlTextColor]);
      dtxtCol = RETAIN([NSColor disabledControlTextColor]);
      clearCol = RETAIN([NSColor clearColor]);
    }

  return self;
}

- init
{
  return [self initTextCell: @""];
}

- (id) initImageCell: (NSImage*)anImage
{
  [super init];

  [self _init];

  NSAssert(anImage == nil || [anImage isKindOfClass: imageClass],
	NSInvalidArgumentException);

  cell_type = NSImageCellType;
  cell_image = RETAIN(anImage);
  image_position = NSImageOnly;
  cell_font = RETAIN([NSFont userFontOfSize: 0]);

  return self;
}

- (id) initTextCell: (NSString*)aString
{
  [super init];

  [self _init];

  cell_font = RETAIN([NSFont userFontOfSize: 0]);
  contents = RETAIN(aString);
  cell_type = NSTextCellType;
  text_align = NSCenterTextAlignment;
  cell_float_autorange = YES;
  cell_float_right = 6;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(contents);
  TEST_RELEASE(cell_image);
  TEST_RELEASE(cell_font);
  TEST_RELEASE(represented_object);

  [super dealloc];
}

/*
 * Determining Component Sizes
 */
- (void) calcDrawInfo: (NSRect)aRect
{
}

- (NSSize) cellSize
{
  NSSize borderSize, s;
  
  // Get border size
  if (cell_bordered)
    borderSize = [cellClass sizeForBorderType: NSLineBorder];
  else if (cell_bezeled)
    borderSize = [cellClass sizeForBorderType: NSBezelBorder];
  else
    borderSize = [cellClass sizeForBorderType: NSNoBorder];

  // Get Content Size
  switch (cell_type)
    {
    case NSTextCellType:
      s = NSMakeSize([cell_font widthOfString: contents], 
		     [cell_font pointSize]);
      // If text, add in a distance between text and borders
      // otherwise the text will mess up with the borders
      s.width += 2 * xDist;
      s.height += 2 * yDist;
      break;
    case NSImageCellType:
      s = [cell_image size];
      break;
    case NSNullCellType:
      s = NSZeroSize;
      break;
    }

  // Add in border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;
  
  return s;
}

- (NSSize) cellSizeForBounds: (NSRect)aRect
{
  // TODO
  return NSZeroSize;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // Get border size
  if (cell_bordered)
    borderSize = [cellClass sizeForBorderType: NSLineBorder];
  else if (cell_bezeled)
    borderSize = [cellClass sizeForBorderType: NSBezelBorder];
  else
    borderSize = [cellClass sizeForBorderType: NSNoBorder];
  
  return NSInsetRect (theRect, borderSize.width, borderSize.height);
}

- (NSRect) imageRectForBounds: (NSRect)theRect
{
  return [self drawingRectForBounds: theRect];
}

- (NSRect) titleRectForBounds: (NSRect)theRect
{
  return [self drawingRectForBounds: theRect];
}

/*
 * Setting the NSCell's Type
 */
- (void) setType: (NSCellType)aType
{
  cell_type = aType;
}

- (NSCellType) type
{
  return cell_type;
}

/*
 * Setting the NSCell's State
 */
- (void) setState: (int)value
{
  cell_state = value;
}

- (int) state
{
  return cell_state;
}

/*
 * Enabling and Disabling the NSCell
 */
- (BOOL) isEnabled
{
  return cell_enabled;
}

- (void) setEnabled: (BOOL)flag
{
  cell_enabled = flag;
}

/*
 * Determining the first responder
 */
- (BOOL) acceptsFirstResponder
{
  return cell_enabled;
}

/*
 * Setting the Image
 */
- (NSImage*) image
{
  return cell_image;
}

- (void) setImage: (NSImage*)anImage
{
  NSAssert(anImage == nil || [anImage isKindOfClass: imageClass],
	NSInvalidArgumentException);

  ASSIGN(cell_image, anImage);
  [self setType: NSImageCellType];
}

/*
 * Setting the NSCell's Value
 */
- (double) doubleValue
{
  return [contents doubleValue];
}

- (float) floatValue
{
  return [contents floatValue];
}

- (int) intValue
{
  return [contents intValue];
}

- (NSString*) stringValue
{
  return contents;
}

- (void) setDoubleValue: (double)aDouble
{
  NSString* number_string = [[NSNumber numberWithDouble: aDouble] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setFloatValue: (float)aFloat
{
  NSString* number_string = [[NSNumber numberWithFloat: aFloat] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setIntValue: (int)anInt
{
  NSString* number_string = [[NSNumber numberWithInt: anInt] stringValue];

  ASSIGN(contents, number_string);
}

- (void) setStringValue: (NSString *)aString
{
  NSString* _string;

  if (!aString)
    _string = @"";
  else
    _string = [aString copy];

  if (contents)
    RELEASE(contents);
  contents = _string;
}

/*
 * Interacting with Other NSCells
 */
- (void) takeDoubleValueFrom: (id)sender
{
  [self setDoubleValue: [sender doubleValue]];
}

- (void) takeFloatValueFrom: (id)sender
{
  [self setFloatValue: [sender floatValue]];
}

- (void) takeIntValueFrom: (id)sender
{
  [self setIntValue: [sender intValue]];
}

- (void) takeStringValueFrom: (id)sender
{
  [self setStringValue: [sender stringValue]];
}

/*
 * Modifying Text Attributes
 */
- (NSTextAlignment) alignment
{
  return text_align;
}

- (NSFont*) font
{
  return cell_font;
}

- (BOOL) isEditable
{
  return cell_editable;
}

- (BOOL) isSelectable
{
  return cell_selectable || cell_editable;
}

- (BOOL) isScrollable
{
  return cell_scrollable;
}

- (void) setAlignment: (NSTextAlignment)mode
{
  text_align = mode;
}

- (void) setEditable: (BOOL)flag
{
  /*
   *	The cell_editable flag is also checked to see if the cell is selectable
   *	so turning edit on also turns selectability on (until edit is turned
   *	off again).
   */
  cell_editable = flag;
}

- (void) setFont: (NSFont *)fontObject
{
  NSAssert(fontObject == nil || [fontObject isKindOfClass: [NSFont class]],
	NSInvalidArgumentException);

  ASSIGN(cell_font, fontObject);
}

- (void) setSelectable: (BOOL)flag
{
  cell_selectable = flag;

  /*
   *	Making a cell unselectable also makes it uneditable until a
   *	setEditable re-enables it.
   */
  if (!flag)
    cell_editable = NO;
}

- (void) setScrollable: (BOOL)flag
{
  cell_scrollable = flag;
}

- (void) setWraps: (BOOL)flag
{
}

- (BOOL) wraps
{
  return NO;
}

/*
 * Editing Text
 */
- (NSText*) setUpFieldEditorAttributes: (NSText*)textObject
{
  return nil;
}

- (void) editWithFrame: (NSRect)aRect
		inView: (NSView *)controlView
		editor: (NSText *)textObject
	      delegate: (id)anObject
		 event: (NSEvent *)theEvent
{
  if (!controlView || !textObject || !cell_font ||
			(cell_type != NSTextCellType))
    return;

  [textObject setDelegate: anObject];

  aRect.origin.y -= 1;

  [textObject setFrame: aRect];
  [textObject setText: [self stringValue]];
  [controlView addSubview:textObject];  

  [[controlView window] makeFirstResponder: textObject];

  if ([theEvent type] == NSLeftMouseDown)
    [textObject mouseDown:theEvent];
}

/*
 * editing is complete, remove the text obj acting as the field
 * editor from window's view heirarchy, set our contents from it
 */
- (void) endEditing: (NSText*)textObject
{
  [textObject setDelegate: nil];
  [textObject retain];
  [textObject removeFromSuperview];
  [self setStringValue: [textObject text]];
  [textObject setString:@""];
}

- (void) selectWithFrame: (NSRect)aRect
		  inView: (NSView *)controlView
		  editor: (NSText *)textObject
		delegate: (id)anObject
		   start: (int)selStart
		  length: (int)selLength
{
  if (!controlView || !textObject || !cell_font ||
			(cell_type != NSTextCellType))
    return;

  [[controlView window] makeFirstResponder: textObject];

  [textObject setFrame: aRect];
  [textObject setAlignment: text_align];
  [textObject setText: [self stringValue]];
  [textObject setDelegate: anObject];
  [controlView addSubview: textObject];
  [controlView lockFocus];
  NSEraseRect(aRect);
  [controlView unlockFocus];
  [textObject display];
}

/*
 * Validating Input
 */
- (int) entryType
{
  return entry_type;
}

- (BOOL) isEntryAcceptable: (NSString*)aString
{
  return YES;
}

- (void) setEntryType: (int)aType
{
  entry_type = aType;
}

/*
 * Formatting Data
 */
- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned int)leftDigits
			  right: (unsigned int)rightDigits
{
  cell_float_autorange = autoRange;
  cell_float_left = leftDigits;
  cell_float_right = rightDigits;
}

/*
 * Modifying Graphic Attributes
 */
- (BOOL) isBezeled
{
  return cell_bezeled;
}

- (BOOL) isBordered
{
  return cell_bordered;
}

- (BOOL) isOpaque
{
  return NO;
}

- (void) setBezeled: (BOOL)flag
{
  cell_bezeled = flag;
  if (cell_bezeled)
    cell_bordered = NO;
}

- (void) setBordered: (BOOL)flag
{
  cell_bordered = flag;
  if (cell_bordered)
    cell_bezeled = NO;
}

/*
 * Setting Parameters
 */
- (int) cellAttribute: (NSCellAttribute)aParameter
{
  return 0;
}

- (void) setCellAttribute: (NSCellAttribute)aParameter to: (int)value
{
}

/*
 * Displaying
 */
- (NSView*) controlView
{
  return control_view;
}

- (void) setControlView: (NSView*)view
{
  control_view = view;
}

- (NSColor*) textColor
{
  if ([self isEnabled])
    return txtCol;
  else
    return dtxtCol;
}

- (void) _drawText: (NSString *) title inFrame: (NSRect) cellFrame
{
  NSColor *textColor;
  NSFont *font;
  float titleWidth;
  float titleHeight;
  NSDictionary	*dict;

  if (!title)
    return;

  textColor = [self textColor];

  font = [self font];
  if (!font)
    [NSException raise: NSInvalidArgumentException
        format: @"Request to draw a text cell but no font specified!"];
  titleWidth = [font widthOfString: title];
  titleHeight = [font pointSize] - [font descender];

  // Determine the y position of the text
  cellFrame.origin.y = NSMidY (cellFrame) - titleHeight / 2;
  cellFrame.size.height = titleHeight;

  // Determine the x position of text
  switch ([self alignment])
    {
      // ignore the justified and natural alignments
      case NSLeftTextAlignment:
      case NSJustifiedTextAlignment:
      case NSNaturalTextAlignment:
	break;
      case NSRightTextAlignment:
        if (titleWidth < NSWidth (cellFrame))
          {
            float shift = NSWidth (cellFrame) - titleWidth;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
	break;
      case NSCenterTextAlignment:
        if (titleWidth < NSWidth (cellFrame))
          {
            float shift = (NSWidth (cellFrame) - titleWidth) / 2;
            cellFrame.origin.x += shift;
            cellFrame.size.width -= shift;
          }
    }

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
		font, NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		nil];
  [title drawInRect: cellFrame withAttributes: dict];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  cellFrame = [self drawingRectForBounds: cellFrame];
  [controlView lockFocus];

  // Clear the cell frame
  if ([self isOpaque])
    {
      NSColor	*bg;

      if (cell_highlighted)
	bg = hbgCol;
      else
	bg = bgCol;
      [bg set];
      [cell_image setBackgroundColor: bg];
      NSRectFill(cellFrame);
    }
  else
    [cell_image setBackgroundColor: clearCol];

  switch ([self type])
    {
      case NSTextCellType:
	 [self _drawText: [self stringValue] inFrame: cellFrame];
	 break;

      case NSImageCellType:
	if (cell_image)
	  {
	    NSSize size;
	    NSPoint position;

	    size = [cell_image size];
	    position.x = MAX(NSMidX(cellFrame) - (size.width/2.),0.);
	    position.y = MAX(NSMidY(cellFrame) - (size.height/2.),0.);
	    /*
	     * Images are always drawn with their bottom-left corner
	     * at the origin so we must adjust the position to take
	     * account of a flipped view.
	     */
	    if ([control_view isFlipped])
	      position.y += size.height;
	    [cell_image compositeToPoint: position operation: NSCompositeCopy];
	  }
	 break;

      case NSNullCellType:
         break;
    }
    [controlView unlockFocus];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSDebugLog (@"NSCell drawWithFrame: inView: ");

  // Save last view drawn to
  [self setControlView: controlView];

  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  [controlView lockFocus];
  // draw the border if needed
  if ([self isBordered])
    {
      [[NSColor controlDarkShadowColor] set];
      NSFrameRect(cellFrame);
    }
  else if ([self isBezeled])
    {
      NSDrawWhiteBezel(cellFrame, NSZeroRect);
    }

  [controlView unlockFocus];
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (BOOL) isHighlighted
{
  return cell_highlighted;
}

- (void) highlight: (BOOL)lit
	 withFrame: (NSRect)cellFrame
	    inView: (NSView*)controlView
{
  if (cell_highlighted != lit)
    {
      cell_highlighted = lit;
      [self drawWithFrame: cellFrame inView: controlView];
    }
}

/*
 * Target and Action
 */
- (SEL) action
{
  return NULL;
}

- (void) setAction: (SEL)aSelector
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set an action in an NSCell"];
}

- (BOOL) isContinuous
{
  return cell_continuous;
}

- (int) sendActionOn: (int)mask
{
  unsigned int previousMask = action_mask;

  action_mask = mask;

  return previousMask;
}

- (void) setContinuous: (BOOL)flag
{
  cell_continuous = flag;
  [self sendActionOn: (NSLeftMouseUpMask|NSPeriodicMask)];
}

- (void) setTarget: (id)anObject
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set a target in an NSCell"];
}

- (id) target
{
  return nil;
}

- (void) performClick: (id)sender
{
  NSView	*cv;
  NSRect   cvBounds;
  NSWindow *cvWin;

  if (control_view)
    cv = control_view;
  else 
    cv = [NSView focusView];

  cvBounds = [cv bounds];
  cvWin = [cv window];
  
  [self highlight: YES withFrame: cvBounds inView: cv];
  [cvWin flushWindow];
  // Wait approx 1/5 seconds
  [[NSRunLoop currentRunLoop] 
    runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]];

  [self highlight: NO withFrame: cvBounds inView: cv];
  [cvWin flushWindow];

  if ([self action])
    {
      NS_DURING
	{
	  [(NSControl*)cv sendAction: [self action] to: [self target]];
	}
      NS_HANDLER
	{
          [localException raise];
	}
      NS_ENDHANDLER
    }
}
/*
 * Assigning a Tag
 */
- (void) setTag: (int)anInt
{
  [NSException raise: NSInternalInconsistencyException
	      format: @"attempt to set a tag in an NSCell"];
}

- (int) tag
{
  return -1;
}

/*
 * Handling Keyboard Alternatives
 */
- (NSString*) keyEquivalent
{
  return @"";
}

/*
 * Tracking the Mouse
 */
- (BOOL) continueTracking: (NSPoint)lastPoint
		       at: (NSPoint)currentPoint
		   inView: (NSView *)controlView
{
  return YES;
}

- (int) mouseDownFlags
{
  return 0;
}

- (void) getPeriodicDelay: (float *)delay interval: (float *)interval
{
  *delay = 0.1;
  *interval = 0.1;
}

- (BOOL) startTrackingAt: (NSPoint)startPoint inView: (NSView *)controlView
{
  // If the point is in the view then yes start tracking
  if ([controlView mouse: startPoint inRect: [controlView bounds]])
    return YES;
  else
    return NO;
}

- (void) stopTracking: (NSPoint)lastPoint
		   at: (NSPoint)stopPoint
	       inView: (NSView *)controlView
	    mouseIsUp: (BOOL)flag
{
}

- (BOOL) trackMouse: (NSEvent *)theEvent
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView
       untilMouseUp: (BOOL)flag
{
  NSApplication	*theApp = [NSApplication sharedApplication];
  unsigned	event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask
			    | NSMouseMovedMask | NSLeftMouseDraggedMask
			    | NSRightMouseDraggedMask;
  NSPoint	location = [theEvent locationInWindow];
  NSPoint	point = [controlView convertPoint: location fromView: nil];
  float		delay;
  float		interval;
  id		target = [self target];
  SEL		action = [self action];
  NSPoint	last_point = point;
  BOOL		done;
  BOOL		mouseWentUp;

  NSDebugLog(@"NSCell start tracking\n");
  NSDebugLog(@"NSCell tracking in rect %f %f %f %f\n",
		      cellFrame.origin.x, cellFrame.origin.y,
		      cellFrame.size.width, cellFrame.size.height);
  NSDebugLog(@"NSCell initial point %f %f\n", point.x, point.y);

  if (![self startTrackingAt: point inView: controlView])
    return NO;

  if (![controlView mouse: point inRect: cellFrame])
    return NO;	// point is not in cell

  if ((action_mask & NSLeftMouseDownMask)
    && [theEvent type] == NSLeftMouseDown)
    [(NSControl*)controlView sendAction: action to: target];

  if (cell_continuous)
    {
      [self getPeriodicDelay: &delay interval: &interval];
      [NSEvent startPeriodicEventsAfterDelay: delay withPeriod: interval];
      event_mask |= NSPeriodicMask;
    }

  NSDebugLog(@"NSCell get mouse events\n");
  mouseWentUp = NO;
  done = NO;
  while (!done)
    {
      NSEventType	eventType;
      BOOL		pointIsInCell;
      unsigned		periodCount = 0;

      theEvent = [theApp nextEventMatchingMask: event_mask
				     untilDate: nil
				        inMode: NSEventTrackingRunLoopMode
				       dequeue: YES];
      eventType = [theEvent type];

      if (eventType != NSPeriodic || periodCount == 4)
	{
	  last_point = point;
	  if (eventType == NSPeriodic)
	    {
	      NSWindow	*w = [controlView window];

	      /*
	       * Too many periodic events in succession - 
	       * update the mouse location and reset the counter.
	       */
	      location = [w mouseLocationOutsideOfEventStream];
	      periodCount = 0;
	    }
	  else
	    {
	      location = [theEvent locationInWindow];
	    }
	  point = [controlView convertPoint: location fromView: nil];
	  NSDebugLog(@"NSCell location %f %f\n", location.x, location.y);
	  NSDebugLog(@"NSCell point %f %f\n", point.x, point.y);
	}
      else
	{
	  periodCount++;
	  NSDebugLog (@"got a periodic event");
	}

      if (![controlView mouse: point inRect: cellFrame])
	{
	  NSDebugLog(@"NSCell point not in cell frame\n");

	  pointIsInCell = NO;	// Do we return now or keep tracking?
	  if (![[self class] prefersTrackingUntilMouseUp] && flag)
	    {
	      NSDebugLog(@"NSCell return immediately\n");
	      done = YES;
	    }
	}
      else
	{
	  pointIsInCell = YES;
	}

      if (!done && ![self continueTracking: last_point 	// should continue
					at: point 	// tracking?
				    inView: controlView])
	{
	  NSDebugLog(@"NSCell stop tracking\n");
	  done = YES;
	}
										      // Did the mouse go up?
      if (eventType == NSLeftMouseUp)
	{
	  NSDebugLog(@"NSCell mouse went up\n");
	  mouseWentUp = YES;
	  done = YES;
          [self setState: ![self state]];
	  if ((action_mask & NSLeftMouseUpMask))
	    [(NSControl*)controlView sendAction: action to: target];
	}
      else
	{
	  if (pointIsInCell && ((eventType == NSLeftMouseDragged
			  && (action_mask & NSLeftMouseDraggedMask))
			  || ((eventType == NSPeriodic)
			  && (action_mask & NSPeriodicMask))))
	    [(NSControl*)controlView sendAction: action to: target];
	}
    }
  // Tell ourselves to stop tracking
  [self stopTracking: last_point
		  at: point
	      inView: controlView
	   mouseIsUp: mouseWentUp];

  if (cell_continuous)
    [NSEvent stopPeriodicEvents];
  // Return YES only if the mouse went up within the cell
  if (mouseWentUp && [controlView mouse: point inRect: cellFrame])
    {
      NSDebugLog(@"NSCell mouse went up in cell\n");
      return YES;
    }

  NSDebugLog(@"NSCell mouse did not go up in cell\n");
  return NO;				// Otherwise return NO
}

/*
 * Managing the Cursor
 */
- (void) resetCursorRect: (NSRect)cellFrame inView: (NSView *)controlView
{
}

/*
 * Comparing to Another NSCell
 */
- (NSComparisonResult) compare: (id)otherCell
{
  if ([otherCell isKindOfClass: [NSCell class]] == NO)
    [NSException raise: NSBadComparisonException
		format: @"NSCell comparison with non-NSCell"];
  if (cell_type != NSTextCellType
    || ((NSCell*)otherCell)->cell_type != NSTextCellType)
    [NSException raise: NSBadComparisonException
		format: @"Comparison between non-text cells"];
  return [contents compare: ((NSCell*)otherCell)->contents];
}

/*
 * Using the NSCell to Represent an Object
 */
- (id) representedObject
{
  return represented_object;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN(represented_object, anObject);
}

- (id) copyWithZone: (NSZone*)zone
{
  NSCell	*c = [[isa allocWithZone: zone] init];

  c->contents = [contents copyWithZone: zone];
  ASSIGN(c->cell_image, cell_image);
  ASSIGN(c->cell_font, cell_font);
  c->cell_state = cell_state;
  c->cell_highlighted = cell_highlighted;
  c->cell_enabled = cell_enabled;
  c->cell_editable = cell_editable;
  c->cell_bordered = cell_bordered;
  c->cell_bezeled = cell_bezeled;
  c->cell_scrollable = cell_scrollable;
  c->cell_selectable = cell_selectable;
  [c setContinuous: cell_continuous];
  c->cell_float_autorange = cell_float_autorange;
  c->cell_float_left = cell_float_left;
  c->cell_float_right = cell_float_right;
  c->image_position = image_position;
  c->cell_type = cell_type;
  c->text_align = text_align;
  c->entry_type = entry_type;
  c->control_view = control_view;
  c->cell_size = cell_size;
  [c setRepresentedObject: represented_object];

  return c;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: contents];
  [aCoder encodeObject: cell_image];
  [aCoder encodeObject: cell_font];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_state];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_highlighted];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_enabled];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_editable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_bordered];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_bezeled];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_scrollable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_selectable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_continuous];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &cell_float_autorange];
  [aCoder encodeValueOfObjCType: "I" at: &cell_float_left];
  [aCoder encodeValueOfObjCType: "I" at: &cell_float_right];
  [aCoder encodeValueOfObjCType: "I" at: &image_position];
  [aCoder encodeValueOfObjCType: "i" at: &cell_type];
  [aCoder encodeValueOfObjCType: @encode(NSTextAlignment) at: &text_align];
  [aCoder encodeValueOfObjCType: "i" at: &entry_type];
  [aCoder encodeConditionalObject: control_view];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &contents];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &cell_font];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_state];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_highlighted];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_enabled];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_editable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_bordered];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_bezeled];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_scrollable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_selectable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_continuous];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &cell_float_autorange];
  [aDecoder decodeValueOfObjCType: "I" at: &cell_float_left];
  [aDecoder decodeValueOfObjCType: "I" at: &cell_float_right];
  [aDecoder decodeValueOfObjCType: "I" at: &image_position];
  [aDecoder decodeValueOfObjCType: "i" at: &cell_type];
  [aDecoder decodeValueOfObjCType: @encode(NSTextAlignment) at: &text_align];
  [aDecoder decodeValueOfObjCType: "i" at: &entry_type];
  control_view = [aDecoder decodeObject];
  return self;
}

@end

/*
 * Methods the backend should implement
 */
@implementation NSCell (GNUstepBackend)

+ (NSSize) sizeForBorderType: (NSBorderType)aType
{
  // Returns the size of a border
  switch (aType)
    {
      case NSLineBorder:
        return NSMakeSize(1, 1);
      case NSGrooveBorder:
      case NSBezelBorder:
        return NSMakeSize(2, 2);
      case NSNoBorder:
      default:
        return NSZeroSize;
    }
}

@end

