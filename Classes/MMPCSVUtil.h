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

#import <Foundation/Foundation.h>

typedef void(^MMPCSVFieldBlock)(id field, NSInteger index);
typedef void(^MMPCSVRecordBlock)(id record);
typedef void(^MMPCSVCommentBlock)(NSString *comment);
typedef void(^MMPCSVErrorBlock)(NSError *error);
typedef BOOL(^MMPCSVFilterBlock)(id record);
typedef id(^MMPCSVMapBlock)(id record);

extern NSString * const MMPCSVErrorDomain;

typedef NS_ENUM(NSInteger, MMPCSVErrorCode) {
    /**
     *  Indicates that a delimited file is incorrectly formatted.
     *  For example, perhaps a double quote is in the wrong position.
     */
    MMPCSVErrorCodeInvalidFormat = 1,
    
    /**
     *  When using useFirstLineAsKeys, all of the lines in the file
     *  must have the same number of fields. If they do not, parsing is aborted and this error is returned.
     */
    MMPCSVErrorCodeIncorrectNumberOfFields
};

@interface MMPCSVFormat : NSObject

+ (instancetype)defaultFormat;

- (instancetype)delimiter:(unichar)delimiter;
- (instancetype)recognizeComments;
- (instancetype)recognizeBackslashesAsEscapes;
- (instancetype)recognizeLeadingEqualSign;
- (instancetype)useFirstLineAsKeys;
- (instancetype)sanitizeFields;
- (instancetype)trimWhitespace;


@end

@interface MMPCSV : NSObject

@property (nonatomic, strong) MMPCSVFormat *format;

+ (instancetype)readURL:(NSURL *)url;

- (instancetype)format:(MMPCSVFormat *)format;

- (instancetype)begin:(MMPCSVRecordBlock)block;
- (instancetype)end:(void (^)(void))block;
- (instancetype)field:(MMPCSVFieldBlock)block;
- (instancetype)comment:(MMPCSVCommentBlock)block;
- (instancetype)error:(MMPCSVErrorBlock)block;

- (instancetype)filter:(MMPCSVFilterBlock)block;
- (instancetype)map:(MMPCSVMapBlock)block;

- (void)each:(MMPCSVRecordBlock)block;
- (NSArray *)all;

@end

