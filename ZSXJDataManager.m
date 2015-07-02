//
//  ZSXJDataManager.m
//  MS_CoreData
//
//  Created by ZSXJ on 15/1/22.
//  Copyright (c) 2015年 ZSXJ. All rights reserved.
//

#import "ZSXJDataManager.h"
#define NAME_MANAGED_MODEL   @"BaseModel"


@implementation ZSXJDataManager
{
    NSInteger defaultBatchSize;
    NSInteger defaultLimitNum;
    NSString *defaultEntityName;
    NSString *defaultEntityPrimary;
}
#pragma mark -
+ (ZSXJDataManager *)sharedDataManager
{
    static ZSXJDataManager *sharedDataManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedDataManager = [[ZSXJDataManager alloc] init];
    });
    return sharedDataManager;
    
}
- (ZSXJDataManager *)init
{
    self = [super init];
    if (self) {
        defaultBatchSize = 15;
    }
    return self;
}
- (void)setBatchSize:(int)batchSize andLimt:(NSInteger)limitNum
{
    defaultBatchSize = batchSize;
    defaultLimitNum = limitNum;
}
/**
 *  Before use the instance method,set entityName and Primary key is demanded
 *
 *  @param entityName       To recognize a entity by it's name.
 *  @param entityPrimaryKey Sometimes when we insert a record,we should confirm it is unique one.
 */
- (void)setEntity:(NSString *)entityName andPrimaryKey:(NSString *)entityPrimaryKey
{
    defaultEntityName = entityName;
    defaultEntityPrimary = entityPrimaryKey;
}
/**
 *  Description
 *
 *  @param entityName     The name of a exist entity in Model
 *  @param descriptor Sort descriptor
 *
 *  @return The fetched result from persisiten store
 */
- (NSArray *)queryWithEntity:(NSString *)entityName andDescriptor:(NSSortDescriptor *)descriptor
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[descriptor]];
    [fetchRequest setFetchLimit:defaultLimitNum];
    NSError *fetchError = nil;
    NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        NSLog(@"There is something wrong with fetchRequest <%@>",fetchError);
        return nil;
    }
    return fetchResult;
}
- (NSArray *)queryWithEntity:(NSString *)entityName andDescriptor:(NSArray *)descriptors andPredicate:(NSPredicate *)sortPredicate
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setFetchLimit:defaultLimitNum];
    [fetchRequest setEntity:entity];
    if (0 < [descriptors count]) {
        [fetchRequest setSortDescriptors:descriptors];
    }
    [fetchRequest setPredicate:sortPredicate];
    NSError *fetchError = nil;
    NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        NSLog(@"There is something wrong with fetchRequest <%@>",fetchError);
        return nil;
    }
    return fetchResult;
}
#pragma mark -
/**
 *  Save the result from net.
 *
 *  @param Entities The items in the arrys should be NSManagedObject or dirctly a dictionary.
 *
 *  @return If everything is allright will return yes.
 */
- (BOOL)saveEntities:(NSArray *)entities
{
    //TODO:How to affirm a record is a exist one
    if ([entities[0] isKindOfClass:[NSManagedObject class]]) {
        //TODO: insert the array
        for (NSManagedObject *managedObject in entities) {
            [self insertARecord:managedObject withPrimaryKey:defaultEntityPrimary];
        }
        return YES;
    }
    else if([entities[0] isKindOfClass:[NSDictionary class]])
    {
        //TODO: insert the array
        for (NSDictionary *dict in entities) {
            NSEntityDescription *description = [NSEntityDescription entityForName:defaultEntityName inManagedObjectContext:self.managedObjectContext];
            NSManagedObject *aNewRecord = [[NSManagedObject alloc] initWithEntity:description insertIntoManagedObjectContext:self.managedObjectContext];
            for (NSString *key in [dict allKeys]) {
                //!!!When create a entity it's attribut must be the same with it's dictionary
                [aNewRecord setValue:[dict objectForKey:key] forKey:key];
            }
        }
        return YES;
    }
    else
        return NO;
}
- (BOOL)insertARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey
{
    //Check if the managed object is repeated
    NSEntityDescription *entityDes = [NSEntityDescription entityForName:defaultEntityName inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *checkFetchRequest = [[NSFetchRequest alloc] init];
    [checkFetchRequest setEntity:entityDes];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K==%@",primaryKey,[aRecord valueForKey:primaryKey]];
    [checkFetchRequest setPredicate:predicate];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:primaryKey ascending:YES];
    [checkFetchRequest setSortDescriptors:@[descriptor]];
    NSFetchedResultsController *fetchedController = [[NSFetchedResultsController alloc] initWithFetchRequest:checkFetchRequest managedObjectContext:[self managedObjectContext] sectionNameKeyPath:primaryKey cacheName:nil];
    fetchedController.delegate = self;
    
    NSError *fetchError = nil;
    [fetchedController performFetch:&fetchError];
    NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:checkFetchRequest error:&fetchError];
    if (fetchError) {
        //Unable to fetche the record
        return NO;
    }
    else
    {
        if (0 < [fetchResult count]) {
            //Update
            if (1 < [fetchResult count]) {
                for (int i = 0; i < [fetchResult count]-1; i++) {
                    [[self managedObjectContext] deleteObject:fetchResult[i]];
                }
            }
            //Update a exist record
            NSDictionary *attributes = [entityDes attributesByName];
            for (NSString *key in [attributes allKeys]) {
                NSManagedObject *theExistingRecord = (NSManagedObject *)[fetchResult lastObject];
                [theExistingRecord setValue:[aRecord valueForKey:key] forKey:key];
            }
        }
        else
        {
            //Insert
            [self.managedObjectContext insertObject:aRecord];
        }
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        return (saveError == nil)?YES:NO;
    }
}
- (BOOL)updateARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey
{
    //Check if there is a exist record
    NSEntityDescription *entityDes = [NSEntityDescription entityForName:defaultEntityName inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *checkFetchRequest = [[NSFetchRequest alloc] init];
    [checkFetchRequest setEntity:entityDes];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K==%@",primaryKey,[aRecord valueForKey:primaryKey]];
    [checkFetchRequest setPredicate:predicate];
    NSError *fetchError = nil;
    NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:checkFetchRequest error:&fetchError];
    if (fetchError) {
        NSLog(@"There is something wrong with fetchRequest");
        return NO;
    }
    else
    {
        if (0 < [fetchResult count]) {
            //There exist the record with primary key --Update it.
            [self.managedObjectContext deleteObject:fetchResult[0]];
            [self.managedObjectContext insertObject:aRecord];
        }
        else
        {
            //There doesn't exist the record -- Insert it.
            [self.managedObjectContext insertObject:aRecord];
        }
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        return saveError == nil?YES:NO;
    }
}
- (BOOL)deleteARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey
{
    NSEntityDescription *entityDes = [NSEntityDescription entityForName:defaultEntityName inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDes];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K==%@",primaryKey,[aRecord valueForKey:primaryKey]];
    [fetchRequest setPredicate:predicate];
    NSError *fetchError = nil;
    NSArray *fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        return NO;
    }
    else
    {
        if (0 < [fetchResult count]) {
            for (NSManagedObject *obj in fetchResult) {
                [self.managedObjectContext deleteObject:obj];
            }
        }
        else
            return NO;
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        return ( saveError == nil )?YES:NO;
    }
}
- (void)synchronizeTheStore
{
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
    if (saveError) {
        NSLog(@"Unable to save context");
    }
}
//- (BOOL)clearTheStore
//{
//    
//}
#pragma mark -

#pragma mark -
#pragma mark Core Data Stack
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:NAME_MANAGED_MODEL withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    //Create Persistent Sotre and Coordinate
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",NAME_MANAGED_MODEL]];
    NSLog(@"%@",storeURL);
    NSError *createError = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&createError]) {
        //Report the error we got
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = @"There was a error when create or load the saved data";
        dict[NSUnderlyingErrorKey] = createError;
        createError = [NSError errorWithDomain:@"SELF_DEFINED_ERROR_DOMAIN" code:9999 userInfo:dict];
        //TODO : You Should handle the error approperiately
        abort();
    }
    return _persistentStoreCoordinator;
}
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinate  = [self persistentStoreCoordinator];
    if (!coordinate) {
        //TODO: if the coordinate is nil shoudl find some bugs in persistentStoreCoordinate method
        NSLog(@"There is someting wrong with persistentStoreCoordinate");
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinate];
    return _managedObjectContext;
}
- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && [managedObjectContext save:&error]) {
            //TODO:handle the error when the context can't be saved
            if (error) {
                NSLog(@"%@,%@",error,error.localizedDescription);
            }
        }
    }
}
#pragma mark -
#pragma mark Fetched Request Controller Delegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(managerWillChangeData)]) {
        [self.delegate managerWillChangeData];
    }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(managerDidChangeData)]) {
        [self.delegate managerDidChangeData];
    }
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([self.delegate respondsToSelector:@selector(shouldChangeUI:atIndexPath:forType:)]) {
        [self.delegate shouldChangeUI:anObject atIndexPath:indexPath forType:type];
    }
    switch (type) {
        case NSFetchedResultsChangeDelete:
        {
            if ([self.delegate respondsToSelector:@selector(shouldChangeUI:atIndexPath:forType:)]) {
//                [self.delegate respondsToSelector:<#(SEL)#>]
            }
            break;
        }
        case NSFetchedResultsChangeInsert:
        {
            
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            
            break;
        }
        default:
            break;
    }
}
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
//{
//    
//}
@end
