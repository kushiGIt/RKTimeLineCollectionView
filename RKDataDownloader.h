//
//  RKDataDownloader.h
//  RKDataDownloader
//
//  Created by RyousukeKushihata on 2014/11/01.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class RKDataDownloader;

@protocol RKDataDownloaderDelegate;

@interface RKDataDownloader : NSObject<NSURLSessionDelegate>{
    
}

@property id<RKDataDownloaderDelegate>delegate;
/**
 *  data download start. Must use -(id)initWithUrlArray: first.
 */
-(void)startDownloads;
/**
 *  Init and set download url with background session. After use this methods,call -(void)startDownloads.
 *
 *  @param urlArray string url in array.
 *
 *  @return (id)self
 */
-(id)initWithUrlArray_background:(NSArray*)urlArray;
/**
 *  Init and set download url with defaults session. After use this methods,call -(void)startDownloads.
 *
 *  @param urlArray urlArray string url in array.
 *
 *  @return (id)self
 */
-(id)initWithUrlArray_defaults:(NSArray *)urlArray;
/**
 *  Do not use this methods.If you use this methods,app is going to clash.
 *
 *  @return (id)self
 */
+(NSArray*)cheakDuplicationURLString:(NSArray*)needCheakArray;
@end

@protocol RKDataDownloaderDelegate <NSObject>

@optional

/**
 *  Get download file progress.(optinal)
 *
 *  @param progress nsnumber progress
 */
-(void)fileDownloadProgress:(NSNumber*)progress;
/**
 *  You can get data and error when download file finish.
 *
 *  @param data             get from tmp file
 *  @param readingDataError get error when read from tmp file
 *  @param urkStr           get data url
 */
-(void)didFinishDownloadData:(NSData*)data withError:(NSError*)readingDataError dataWithUrl:(NSString*)urlStr;
/**
 *  Call this methods when finished all tasks. もし-(id)initWithUrlArray_defaults:(NSArray *)urlArray;で第一関数にnilをセットしたらNULLが第一、第二関数に代入されます。その場合は-(void)startDownloadsを実行した直後に、このメソッドが呼ばれます。
 *
 *  @param data             get from tmp file
 *  @param readingDataError get error when read from tmp file
 */
-(void)didFinishAllDownloadsWithDataDictinary:(NSDictionary*)dataDic withErrorDic:(NSDictionary*)errorDic;

@end
