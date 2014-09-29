//
//  MMPCSVUtil.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, <http://mamad.purbo.org>
//
//  This library uses code adapted from CHCSVParser (https://github.com/davedelong/CHCSVParser). Copyright (c) 2014 Dave DeLong
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MMPCSVUtil.h"

#define CHUNK_SIZE 512
#define DOUBLE_QUOTE '"'
#define COMMA ','
#define OCTOTHORPE '#'
#define EQUAL '='
#define BACKSLASH '\\'
#define NULLCHAR '\0'

NSString *const MMPCSVErrorDomain = @"org.purbo.csv";

@interface MMPCSVFormat()

@property (nonatomic, assign) unichar delimiter;
@property (nonatomic, assign) BOOL usesFirstLineAsKeys;
@property (nonatomic, assign) BOOL recognizesComments;
@property (nonatomic, assign) BOOL recognizesBackslashesAsEscapes;
@property (nonatomic, assign) BOOL trimsWhitespace;
@property (nonatomic, assign) BOOL recognizesLeadingEqualSign;
@property (nonatomic, assign) BOOL sanitizesFields;
@property (nonatomic, strong) NSCharacterSet *validFieldCharacters;

@end

@implementation MMPCSVFormat

+ (instancetype)defaultFormat
{
    MMPCSVFormat *ret = [MMPCSVFormat new];
    ret.delimiter = ',';
    ret.usesFirstLineAsKeys = NO;
    ret.recognizesComments = NO;
    ret.recognizesBackslashesAsEscapes = NO;
    ret.trimsWhitespace = NO;
    ret.recognizesLeadingEqualSign = NO;
    ret.sanitizesFields = NO;
    
    NSMutableCharacterSet *m = [[NSCharacterSet newlineCharacterSet] mutableCopy];
    NSString *invalid = [NSString stringWithFormat:@"%c%C", DOUBLE_QUOTE, ret.delimiter];
    [m addCharactersInString:invalid];
    ret.validFieldCharacters = [m invertedSet];
    
    return ret;
}

- (instancetype)delimiter:(unichar)delimiter
{
    _delimiter = delimiter;
    return self;
}

- (instancetype)recognizeComments
{
    _recognizesComments = YES;
    return self;
}

- (instancetype)useFirstLineAsKeys
{
    _usesFirstLineAsKeys = YES;
    return self;
}

- (instancetype)sanitizeFields
{
    _sanitizesFields = YES;
    return self;
}

- (instancetype)recognizeBackslashesAsEscapes
{
    _recognizesBackslashesAsEscapes = YES;
    return self;
}

- (instancetype)trimWhitespace
{
    _trimsWhitespace = YES;
    return self;
}

- (instancetype)recognizeLeadingEqualSign
{
    _recognizesLeadingEqualSign = YES;
    return self;
}

@end

@interface MMPCSV()

@property (nonatomic, strong) NSInputStream *stream;
@property (nonatomic, copy) MMPCSVRecordBlock beginBlock;
@property (nonatomic, copy) void(^endBlock)();
@property (nonatomic, copy) MMPCSVFieldBlock fieldBlock;
@property (nonatomic, copy) MMPCSVRecordBlock eachBlock;
@property (nonatomic, copy) MMPCSVCommentBlock commentBlock;
@property (nonatomic, copy) MMPCSVErrorBlock errorBlock;
@property (nonatomic, copy) MMPCSVFilterBlock filterBlock;
@property (nonatomic, copy) MMPCSVMapBlock mapBlock;

@property (nonatomic, strong) NSMutableString *string;
@property (nonatomic, strong) NSMutableData *stringBuffer;
@property (nonatomic, assign) NSUInteger nextIndex;
@property (nonatomic, assign) NSUInteger totalBytesRead;
@property (nonatomic, strong) NSNumber *streamEncoding;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) NSInteger fieldIndex;
@property (nonatomic, assign) NSRange fieldRange;
@property (nonatomic, assign) NSUInteger currentRecord;
@property (nonatomic, strong) NSMutableArray *currentRecordArray;
@property (nonatomic, strong) NSArray *header;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableString *sanitizedField;

@end

@implementation MMPCSV

+ (instancetype)readURL:(NSURL *)url
{
    return [[MMPCSV alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithStream:[NSInputStream inputStreamWithURL:url]];
}

- (instancetype)initWithStream:(NSInputStream *)stream
{
    if (self = [super init]) {
        self.stream = stream;
        self.format = [MMPCSVFormat defaultFormat];
        self.streamEncoding = nil;
        self.error = nil;
    }
    return self;
}

- (instancetype)format:(MMPCSVFormat *)format
{
    self.format = format;
    return self;
}

- (instancetype)encoding:(NSStringEncoding)encoding
{
    self.streamEncoding = @(encoding);
    return self;
}

- (instancetype)begin:(MMPCSVRecordBlock)block
{
    self.beginBlock = block;
    return self;
}

- (instancetype)end:(void (^)(void))block
{
    self.endBlock = block;
    return self;
}

- (instancetype)field:(MMPCSVFieldBlock)block
{
    self.fieldBlock = block;
    return self;
}

- (instancetype)comment:(MMPCSVCommentBlock)block
{
    self.commentBlock = block;
    return self;
}

- (instancetype)error:(MMPCSVErrorBlock)block
{
    self.errorBlock = block;
    return self;
}

- (instancetype)filter:(MMPCSVFilterBlock)block
{
    self.filterBlock = block;
    return self;
}

- (instancetype)map:(MMPCSVMapBlock)block
{
    self.mapBlock = block;
    return self;
}

- (void)each:(MMPCSVRecordBlock)block
{
    self.eachBlock = block;
    [self parse];
}

- (NSArray *)all
{
    __block NSMutableArray *allRecords = [NSMutableArray array];
    self.eachBlock = ^(id record, NSUInteger index) {
        [allRecords addObject:record];
    };
    [self parse];
    return allRecords;
}

- (void)parse
{
    [self initParser];
    
    @autoreleasepool {
        if (!_format.usesFirstLineAsKeys && _beginBlock) {
            _beginBlock(nil, 0);
        }
        
        _currentRecord = 0;
        
        while ([self parseRecord]) {
            ; // yep;
        }
        
        if (_error != nil && _errorBlock) {
            _errorBlock(_error);
        } else {
            if (_endBlock) {
                _endBlock();
            }
        }
    }
}

- (void)initParser
{
    [_stream open];
    
    self.string = [NSMutableString new];
    self.stringBuffer = [NSMutableData new];
    self.sanitizedField = [NSMutableString new];
    self.header = nil;
    
    if (!_streamEncoding) {
        self.streamEncoding = @([self sniffEncoding]);
    }
    
    _nextIndex = 0;
    _totalBytesRead = 0;
    _cancelled = NO;
}

- (BOOL)parseRecord
{
    self.currentRecordArray = [NSMutableArray new];
    
    while ([self peekCharacter] == OCTOTHORPE && _format.recognizesComments) {
        [self parseComment];
    }
    
    if ([self peekCharacter] != NULLCHAR) {
        @autoreleasepool {
            [self beginRecord];
            while (1) {
                if (![self parseField]) {
                    break;
                }
                if (![self parseDelimiter]) {
                    break;
                }
            }
            [self endRecord];
        }
    }
    
    BOOL followedByNewline = [self parseNewline];
    return (followedByNewline && _error == nil && [self peekCharacter] != NULLCHAR);
}

- (BOOL)parseComment
{
    [self advance]; // consume the octothorpe
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    [self beginComment];
    BOOL isBackslashEscaped = NO;
    while (1) {
        if (isBackslashEscaped == NO) {
            unichar next = [self peekCharacter];
            if (next == BACKSLASH && _format.recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self advance];
            } else if ([newlines characterIsMember:next] == NO && next != NULLCHAR) {
                [self advance];
            } else {
                // it's a newline
                break;
            }
        } else {
            isBackslashEscaped = YES;
            [self advance];
        }
    }
    [self endComment];
    
    return [self parseNewline];
}

- (BOOL)parseNewline
{
    if (_cancelled) { return NO; }
    
    NSUInteger charCount = 0;
    while ([[NSCharacterSet newlineCharacterSet] characterIsMember:[self peekCharacter]]) {
        charCount++;
        [self advance];
    }
    return (charCount > 0);
}

- (void)parseFieldWhitespace
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    while ([self peekCharacter] != NULLCHAR &&
           [whitespace characterIsMember:[self peekCharacter]] &&
           [self peekCharacter] != _format.delimiter) {
        
        if (_format.trimsWhitespace == NO) {
            [_sanitizedField appendFormat:@"%C", [self peekCharacter]];
            // if we're sanitizing fields, then these characters would be stripped (because they're not appended to _sanitizedField)
        }
        [self advance];
    }
}

- (BOOL)parseField {
    if (_cancelled) { return NO; }
    
    BOOL parsedField = NO;
    [self beginField];
    
    // consume leading whitespace
    [self parseFieldWhitespace];
    
    if ([self peekCharacter] == DOUBLE_QUOTE) {
        parsedField = [self parseEscapedField];
    } else if (_format.recognizesLeadingEqualSign && [self peekCharacter] == EQUAL && [self peekPeekCharacter] == DOUBLE_QUOTE) {
        [self advance]; // consume the equal sign
        parsedField = [self parseEscapedField];
    } else {
        parsedField = [self parseUnescapedField];
        if (_format.trimsWhitespace) {
            NSString *trimmedString = [_sanitizedField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [_sanitizedField setString:trimmedString];
        }
    }
    
    if (parsedField) {
        // consume trailing whitespace
        [self parseFieldWhitespace];
        [self endField];
    }
    return parsedField;
}

- (BOOL)parseEscapedField {
    [self advance]; // consume the opening double quote
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    BOOL isBackslashEscaped = NO;
    while (1) {
        unichar next = [self peekCharacter];
        if (next == NULLCHAR) { break; }
        
        if (isBackslashEscaped == NO) {
            if (next == BACKSLASH && _format.recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self advance]; // consume the backslash
            } else if ([_format.validFieldCharacters characterIsMember:next] ||
                       [newlines characterIsMember:next] ||
                       next == _format.delimiter) {
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
            } else if (next == DOUBLE_QUOTE && [self peekPeekCharacter] == DOUBLE_QUOTE) {
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
                [self advance];
            } else {
                // not valid, or it's not a doubled double quote
                break;
            }
        } else {
            [_sanitizedField appendFormat:@"%C", next];
            isBackslashEscaped = NO;
            [self advance];
        }
    }
    
    if ([self peekCharacter] == DOUBLE_QUOTE) {
        [self advance];
        return YES;
    }
    
    return NO;
}

- (BOOL)parseUnescapedField {
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    BOOL isBackslashEscaped = NO;
    while (1) {
        unichar next = [self peekCharacter];
        if (next == NULLCHAR) { break; }
        
        if (isBackslashEscaped == NO) {
            if (next == BACKSLASH && _format.recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self advance];
            } else if ([newlines characterIsMember:next] == YES || next == _format.delimiter) {
                break;
            } else {
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
            }
        } else {
            isBackslashEscaped = NO;
            [_sanitizedField appendFormat:@"%C", next];
            [self advance];
        }
    }
    
    return YES;
}

- (BOOL)parseDelimiter {
    unichar next = [self peekCharacter];
    if (next == _format.delimiter) {
        [self advance];
        return YES;
    }
    if (next != NULLCHAR && [[NSCharacterSet newlineCharacterSet] characterIsMember:next] == NO) {
        NSString *description = [NSString stringWithFormat:@"Unexpected delimiter. Expected '%C' (0x%X), but got '%C' (0x%X)", _format.delimiter, _format.delimiter, [self peekCharacter], [self peekCharacter]];
        _error = [[NSError alloc] initWithDomain:MMPCSVErrorDomain code:MMPCSVErrorCodeInvalidFormat userInfo:@{NSLocalizedDescriptionKey : description}];
    }
    return NO;
}

- (void)beginComment
{
    if (_cancelled) { return; }
    _fieldRange.location = _nextIndex;
}

- (void)endComment
{
    if (_cancelled) { return; }
    
    _fieldRange.length = (_nextIndex - _fieldRange.location);
    if (_commentBlock) {
        _commentBlock([_string substringWithRange:_fieldRange]);
    }
    
    [_string replaceCharactersInRange:NSMakeRange(0, NSMaxRange(_fieldRange)) withString:@""];
    _nextIndex = 0;
}

- (void)beginRecord
{
    if (_cancelled) { return; }
    
    _fieldIndex = 0;
    _currentRecord++;
}

- (void)endRecord
{
    if (_cancelled) { return; }
    
    id record = nil;
    
    if (_format.usesFirstLineAsKeys) {
        if (!_header) {
            // must be first record because _header is still nil
            self.header = [NSArray arrayWithArray:_currentRecordArray];
            if (_beginBlock) {
                _beginBlock(_header, _currentRecord);
            }
        } else {
            // make sure size is the same as header
            if ([_currentRecordArray count] == [_header count]) {
                NSMutableDictionary *dictRecord = [NSMutableDictionary new];
                NSUInteger i = 0;
                for (NSString *headerField in _header) {
                    [dictRecord setObject:[_currentRecordArray objectAtIndex:i] forKey:headerField];
                    i++;
                }
                record = dictRecord;
            } else {
                _error = [[NSError alloc] initWithDomain:MMPCSVErrorDomain code:MMPCSVErrorCodeIncorrectNumberOfFields userInfo:nil];
                return;
            }
        }
    } else {
        record = _currentRecordArray;
    }
    
    if (record && _eachBlock) {
        if (_mapBlock) {
            record = _mapBlock(record);
        }
        if (!_filterBlock || (_filterBlock && _filterBlock(record))) {
            _eachBlock(record, _currentRecord);
        }
    }
}

- (void)beginField
{
    if (_cancelled) { return; }
    
    [_sanitizedField setString:@""];
    _fieldRange.location = _nextIndex;
}

- (void)endField
{
    if (_cancelled) { return; }
    
    _fieldRange.length = (_nextIndex - _fieldRange.location);
    NSString *field = nil;
    
    if (_format.sanitizesFields) {
        field = [_sanitizedField copy];
    } else {
        field = [_string substringWithRange:_fieldRange];
        if (_format.trimsWhitespace) {
            field = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    
    [_currentRecordArray addObject:field];
    
    if (_fieldBlock) {
        _fieldBlock(field, _fieldIndex);
    }
    
    [_string replaceCharactersInRange:NSMakeRange(0, NSMaxRange(_fieldRange)) withString:@""];
    _nextIndex = 0;
    _fieldIndex++;
}

- (void)advance
{
    [self loadMoreIfNecessary];
    _nextIndex++;
}

- (unichar)peekCharacter
{
    [self loadMoreIfNecessary];
    if (_nextIndex >= [_string length]) { return NULLCHAR; }
    return [_string characterAtIndex:_nextIndex];
}

- (unichar)peekPeekCharacter {
    [self loadMoreIfNecessary];
    NSUInteger nextNextIndex = _nextIndex+1;
    if (nextNextIndex >= [_string length]) { return NULLCHAR; }
    
    return [_string characterAtIndex:nextNextIndex];
}

- (void)loadMoreIfNecessary
{
    NSUInteger stringLength = [_string length];
    NSUInteger reloadPortion = stringLength / 3;
    if (reloadPortion < 10) { reloadPortion = 10; }
    
    if ([_stream hasBytesAvailable] && _nextIndex + reloadPortion >= stringLength) {
        // read more from the stream
        uint8_t buffer[CHUNK_SIZE];
        NSInteger readBytes = [_stream read:buffer maxLength:CHUNK_SIZE];
        if (readBytes > 0) {
            // append it to the buffer
            [_stringBuffer appendBytes:buffer length:readBytes];
            _totalBytesRead = _totalBytesRead + readBytes;
        }
    }
    
    if ([_stringBuffer length] > 0) {
        // try to turn the next portion of the buffer into a string
        NSUInteger readLength = [_stringBuffer length];
        while (readLength > 0) {
            NSString *readString = [[NSString alloc] initWithBytes:[_stringBuffer bytes] length:readLength encoding:[_streamEncoding unsignedIntegerValue]];
            if (readString == nil) {
                readLength--;
            } else {
                [_string appendString:readString];
                break;
            }
        };
        
        [_stringBuffer replaceBytesInRange:NSMakeRange(0, readLength) withBytes:NULL length:0];
    }
}

- (NSStringEncoding)sniffEncoding
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    uint8_t bytes[CHUNK_SIZE];
    NSInteger readLength = [_stream read:bytes maxLength:CHUNK_SIZE];
    if (readLength > 0 && readLength <= CHUNK_SIZE) {
        [_stringBuffer appendBytes:bytes length:readLength];
        [self setTotalBytesRead:[self totalBytesRead] + readLength];
        
        NSInteger bomLength = 0;
        
        if (readLength > 3 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF) {
            encoding = NSUTF32BigEndianStringEncoding;
            bomLength = 4;
        } else if (readLength > 3 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00) {
            encoding = NSUTF32LittleEndianStringEncoding;
            bomLength = 4;
        } else if (readLength > 3 && bytes[0] == 0x1B && bytes[1] == 0x24 && bytes[2] == 0x29 && bytes[3] == 0x43) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_KR);
            bomLength = 4;
        } else if (readLength > 1 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
            encoding = NSUTF16BigEndianStringEncoding;
            bomLength = 2;
        } else if (readLength > 1 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
            encoding = NSUTF16LittleEndianStringEncoding;
            bomLength = 2;
        } else if (readLength > 2 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
            encoding = NSUTF8StringEncoding;
            bomLength = 3;
        } else {
            NSString *bufferAsUTF8 = nil;
            
            for (NSInteger triedLength = 0; triedLength < 4; ++triedLength) {
                bufferAsUTF8 = [[NSString alloc] initWithBytes:bytes length:readLength-triedLength encoding:NSUTF8StringEncoding];
                if (bufferAsUTF8 != nil) {
                    break;
                }
            }
            
            if (bufferAsUTF8 != nil) {
                encoding = NSUTF8StringEncoding;
            } else {
                NSLog(@"unable to determine stream encoding; assuming MacOSRoman");
                encoding = NSMacOSRomanStringEncoding;
            }
        }
        
        if (bomLength > 0) {
            [_stringBuffer replaceBytesInRange:NSMakeRange(0, bomLength) withBytes:NULL length:0];
        }
    }
    
    return encoding;
}

@end

