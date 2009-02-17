/* Copyright © 2007-2008, The Sequential Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the the Sequential Project nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE SEQUENTIAL PROJECT ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE SEQUENTIAL PROJECT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "PGCFMutableArray.h"

static CFIndex PGUnsignedToCFIndex(unsigned i)
{
	return NSNotFound == i ? kCFNotFound : (CFIndex)i;
}
static unsigned PGCFIndexToUnsigned(CFIndex i)
{
	return kCFNotFound == i ? NSNotFound : (unsigned)i;
}

@implementation PGCFMutableArray

#pragma mark PGExtendedMutableArray Protocol

- (id)initWithCallbacks:(CFArrayCallBacks const *)callbacks
{
	if((self = [super init])) {
		_array = CFArrayCreateMutable(kCFAllocatorDefault, 0, callbacks);
	}
	return self;
}

#pragma mark NSExtendedMutableArray Protocol

- (void)removeAllObjects
{
	CFArrayRemoveAllValues(_array);
}
- (void)addObjectsFromArray:(NSArray *)otherArray
{
	CFArrayAppendArray(_array, (CFArrayRef)otherArray, CFRangeMake(0, CFArrayGetCount((CFArrayRef)otherArray)));
}
- (void)removeObject:(id)anObject
        inRange:(NSRange)range
{
	CFIndex const start = PGUnsignedToCFIndex(range.location);
	CFIndex i = PGUnsignedToCFIndex(NSMaxRange(range));
	while(kCFNotFound != (i = CFArrayGetLastIndexOfValue(_array, CFRangeMake(start, i - start), anObject))) CFArrayRemoveValueAtIndex(_array, i);
}
- (void)removeObject:(id)anObject
{
	return [self removeObject:anObject inRange:NSMakeRange(0, [self count])];
}
- (void)removeObjectIdenticalTo:(id)anObject
        inRange:(NSRange)range
{
	return [self removeObject:anObject inRange:range];
}
- (void)removeObjectIdenticalTo:(id)anObject
{
	return [self removeObjectIdenticalTo:anObject inRange:NSMakeRange(0, [self count])];
}

#pragma mark NSExtendedArray Protocol

- (BOOL)containsObject:(id)anObject
{
	return kCFNotFound != CFArrayGetFirstIndexOfValue(_array, CFRangeMake(0, CFArrayGetCount(_array)), anObject);
}
- (NSString *)description
{
	return [(NSString *)CFCopyDescription(_array) autorelease];
}
- (BOOL)isEqualToArray:(NSArray *)otherArray
{
	return CFEqual(_array, (CFArrayRef)otherArray);
}
- (unsigned)indexOfObject:(id)anObject
              inRange:(NSRange)range
{
	return PGCFIndexToUnsigned(CFArrayGetFirstIndexOfValue(_array, CFRangeMake(PGUnsignedToCFIndex(range.location), PGUnsignedToCFIndex(range.length)), anObject));
}
- (unsigned)indexOfObjectIdenticalTo:(id)anObject
            inRange:(NSRange)range
{
	return [self indexOfObject:anObject inRange:range];
}

#pragma mark NSMutableArray

- (void)addObject:(id)anObject
{
	CFArrayAppendValue(_array, anObject);
}
- (void)insertObject:(id)anObject
        atIndex:(unsigned)index
{
	CFArrayInsertValueAtIndex(_array, PGUnsignedToCFIndex(index), anObject);
}
- (void)removeLastObject
{
	unsigned const count = [self count];
	if(count) CFArrayRemoveValueAtIndex(_array, PGUnsignedToCFIndex(count - 1));
}
- (void)removeObjectAtIndex:(unsigned)index
{
	CFArrayRemoveValueAtIndex(_array, PGUnsignedToCFIndex(index));
}
- (void)replaceObjectAtIndex:(unsigned)index
        withObject:(id)anObject
{
	CFArraySetValueAtIndex(_array, PGUnsignedToCFIndex(index), anObject);
}

#pragma mark NSArray

- (unsigned)count
{
	return PGCFIndexToUnsigned(CFArrayGetCount(_array));
}
- (id)objectAtIndex:(unsigned)index
{
	return (id)CFArrayGetValueAtIndex(_array, PGUnsignedToCFIndex(index));
}

#pragma mark NSObject

- (id)init
{
	return [self initWithCallbacks:NULL];
}
- (void)dealloc
{
	if(_array) CFRelease(_array);
	[super dealloc];
}

@end

@implementation NSMutableArray (PGExtendedMutableArray)

- (id)initWithCallbacks:(CFArrayCallBacks const *)callbacks
{
	[[self init] release];
	return [[PGCFMutableArray alloc] initWithCallbacks:callbacks];
}

@end
