//
//  MMPCSVUtil.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, <http://mamad.purbo.org>
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

@interface MMPCSVFormat()

@property (nonatomic, assign) unichar delimiter;

@end

@implementation MMPCSVFormat

+ (instancetype)defaultFormat
{
    MMPCSVFormat *ret = [MMPCSVFormat new];
    ret.delimiter = ',';
    return ret;
}

- (MMPCSVFormat *)delimiter:(unichar)delimiter
{
    _delimiter = delimiter;
    return self;
}

@end

@interface MMPCSV()

@property (nonatomic, strong) NSInputStream *stream;
@property (nonatomic, strong) MMPCSVRecordBlock eachBlock;

@property (nonatomic, strong) NSMutableString *string;
@property (nonatomic, strong) NSMutableData *stringBuffer;
@property (nonatomic, assign) NSUInteger nextIndex;
@property (nonatomic, assign) NSUInteger totalBytesRead;
@property (nonatomic, assign) NSStringEncoding streamEncoding;

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
    }
    return self;
}

- (instancetype)format:(MMPCSVFormat *)format
{
    self.format = format;
    return self;
}

- (instancetype)each:(MMPCSVRecordBlock)block
{
    self.eachBlock = block;
    [self parse];
    return self;
}

- (void)parse
{
    [_stream open];
    
    self.string = [NSMutableString new];
    self.stringBuffer = [NSMutableData new];
    _nextIndex = 0;
    _totalBytesRead = 0;
}


- (void)loadMoreIfNecessary {
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
            NSString *readString = [[NSString alloc] initWithBytes:[_stringBuffer bytes] length:readLength encoding:_streamEncoding];
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

@end


@interface MMPCSVUtil () {
}

@end

@implementation MMPCSVUtil

@end
