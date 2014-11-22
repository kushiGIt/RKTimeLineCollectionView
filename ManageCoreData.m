//
//  ManageCoreData.m
//  RKDataDownloader
//
//  Created by RyousukeKushihata on 2014/11/11.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "ManageCoreData.h"

@implementation ManageCoreData
#pragma mark - create manege object
- (NSURL*)createStoreURL {
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path = [[directories lastObject] stringByAppendingPathComponent:@"RKDataDownloader.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:path];
    
    return storeURL;
    
}
- (NSURL*)createModelURL {
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSString *path = [mainBundle pathForResource:@"RKDataLifeTimeModel" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:path];
    
    return modelURL;
    
}
- (NSManagedObjectContext*)createManagedObjectContext {
    
    NSURL *modelURL = [self createModelURL];
    NSURL *storeURL = [self createStoreURL];
    
    NSError *error = nil;
    
    NSManagedObjectModel *managedObjectModel=[[NSManagedObjectModel alloc]initWithContentsOfURL:modelURL];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    
    NSManagedObjectContext *managedObjectContent = [[NSManagedObjectContext alloc] init];
    [managedObjectContent setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    return managedObjectContent;
    
}
#pragma mark  - save
-(void)setContextData:(NSData*)originalData forKey:(NSString*)keyStr ObjectDeleteTime:(NSDate*)objectLongevityDate ischeckDupulicationInEntity:(BOOL)ischeckDupulication withEntityName:(NSString*)entityName{
    
    if (ischeckDupulication) {
        
        NSManagedObject * checkForDuplicate = [self checkDupulicationInEntity:entityName  withKey:keyStr];
        
        if (checkForDuplicate!=NULL) {
            
            [self deleteCoreDataObjectInEntity:entityName withKey:keyStr];
            
        }
        
    }
    
    [self saveContext:originalData forKey:keyStr objectLifeTime:objectLongevityDate withEntityName:entityName];
    
}
-(void)saveContext:(NSData*)data forKey:(NSString*)key objectLifeTime:(NSDate*)date withEntityName:(NSString*)entityName{
    
    NSManagedObjectContext*context=[[NSManagedObjectContext alloc]init];
    context=[self createManagedObjectContext];
    
    DataLifeTime*dataInfo=[NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
    
    dataInfo.data=data;
    dataInfo.key=key;
    dataInfo.object_LifeTime=date;
    
    NSError *error = nil;
    
    if([context save:&error]) {
        
        NSLog(@"Save object to CoreData successfully");
        
    } else {
        
        NSLog(@"Save object to CoreData unsuccessfully");
        
    }
    
}
#pragma mark - get
-(NSArray*)getContextInEntity:(NSString *)entityName withKey:(NSString *)keyString{
    
    NSManagedObjectContext*context=[[NSManagedObjectContext alloc]init];
    context=[self createManagedObjectContext];
    
    NSEntityDescription*entity=[NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSString *searchString = keyString;
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"key == %@",searchString];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchResults = [context executeFetchRequest:request error:&error];
    
    NSMutableArray*resultsArray=[[NSMutableArray alloc]init];
    
    if([fetchResults count] > 0) {
        
        for (DataLifeTime *ent in fetchResults) {
            
            NSDictionary*dic=[[NSDictionary alloc]initWithObjectsAndKeys:ent.key,@"key",ent.data,@"data",ent.object_LifeTime,@"object_LifeTime",nil];
            [resultsArray addObject:dic];
        
        }
        
        return resultsArray;
        
    } else {
        
        NSLog(@"Data is None!");
        
    }
    
    return nil;
    
}
#pragma mark - delete
-(void)deleteEntityData:(NSString *)entityName{
    
    NSManagedObjectContext*managedObjectContext=[[NSManagedObjectContext alloc]init];
    managedObjectContext=[self createManagedObjectContext];
    
    NSFetchRequest * requestDelete = [[NSFetchRequest alloc] init];
    [requestDelete setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
    [requestDelete setIncludesPropertyValues:NO];
    
    NSError * error = nil;
    NSArray * dataArray = [managedObjectContext executeFetchRequest:requestDelete error:&error];
    
    for (NSManagedObject * data in dataArray) {
        [managedObjectContext deleteObject:data];
    }
    
    NSError *saveError = nil;
    if([managedObjectContext save:&saveError]) {
        
        NSLog(@"Delete object to CoreData successfully");
        
    } else {
        
        NSLog(@"Delete object to CoreData unsuccessfully");
        
    };
    
}
-(void)deleteCoreDataObjectInEntity:(NSString *)entityName withKey:(NSString *)keyString{
    
    NSManagedObjectContext*managedObjectContext=[[NSManagedObjectContext alloc]init];
    managedObjectContext=[self createManagedObjectContext];
    
    
    NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] init];
    
    [deleteRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
    [deleteRequest setIncludesPropertyValues:NO];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"key == %@",keyString];
    [deleteRequest setPredicate:predicate];
    
    
    
    NSError *error = nil;
    
    NSArray *results = [managedObjectContext executeFetchRequest:deleteRequest error:&error];
    
    
    for (NSManagedObject *data in results) {
        
        [managedObjectContext deleteObject:data];
        
    }
    
    NSError *saveError = nil;
    
    if([managedObjectContext save:&saveError]) {
        
        NSLog(@"Delete object to CoreData object successfully");
        
    } else {
        
        NSLog(@"Delete object to CoreData object unsuccessfully");
        
    };
    
}
#pragma mark - check dupulication in entity
-(NSManagedObject *)checkDupulicationInEntity:(NSString *)entityName withKey:(NSString *)keyString{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key = %@",keyString];
    [fetchRequest setPredicate:predicate];
    
    NSArray *results = [[self createManagedObjectContext] executeFetchRequest:fetchRequest error:nil];
    
    if (results.count > 0) {
        
        return [results objectAtIndex:0];
        
    }
    
    return NULL;
    
}
#pragma mark - check date in entity
-(NSArray*)checkDateInEntity:(NSString *)entityName isDelete:(BOOL)isDelete{
    
    NSDate*date=[[NSDate dateWithTimeIntervalSinceNow:[[NSTimeZone systemTimeZone]secondsFromGMT]]dateByAddingTimeInterval:1];
    
    NSManagedObjectContext*context=[[NSManagedObjectContext alloc]init];
    context=[self createManagedObjectContext];
    
    NSEntityDescription*entity=[NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"object_LifeTime <= %@",date];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchResults = [context executeFetchRequest:request error:&error];
    
    NSMutableArray*resultsArray=[[NSMutableArray alloc]init];
    
    if([fetchResults count] > 0) {
        
        for (DataLifeTime *ent in fetchResults) {
            
            NSDictionary*dic=[[NSDictionary alloc]initWithObjectsAndKeys:ent.key,@"key",ent.data,@"data",ent.object_LifeTime,@"object_LifeTime",nil];
            [resultsArray addObject:dic];
            
            if (isDelete) {
                
                [self deleteCoreDataObjectInEntity:@"DataLifeTime" withKey:[NSString stringWithFormat:@"%@",ent.key]];
                
            }
            
        }
        
        return resultsArray;
        
    } else {
        
        NSLog(@"Data is None!");
        
    }
    
    return nil;
    
}
@end
