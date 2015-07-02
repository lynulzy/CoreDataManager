//
//  ZSXJDataManager.h
//  MS_CoreData
//
//  Created by ZSXJ on 15/1/22.
//  Copyright (c) 2015年 ZSXJ. All rights reserved.
//
/**
 Notice:
 1.Before using the manager ,you should get an instance from sharedDataManager method
 2.Setting the delegate and implement the delegate methods can also achieve the NSFetchedResultDelegate delegate method
 3.
 */
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
@protocol ZSXJDataManagerDelegate <NSObject>
typedef enum {
    XJDataChangeInsert = 1,
    XJDataChangeDelete = 2,
    XJDataChangeMove = 3,
    XJDataChangeUpdate = 4
}XJDataChangeType;
/**
 *  If some data changed in some rows ,the delegate method is called
 *
 *  @param managedObject Include the Infomation in the Row
 *  @param indexPath     Where is the row
 *  @param type          XJDataChangeType
 */
- (void)shouldChangeUI:(NSManagedObject *)managedObject atIndexPath:(NSIndexPath *)indexPath forType:(NSInteger)type;
//- (void)configureTheCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)theIndexPath;
/**
 *  TableView should start update in this method.
 */
- (void)managerWillChangeData;
/**
 *  TableView should end update in this method.
 */
- (void)managerDidChangeData;

@end

@interface ZSXJDataManager : NSObject<NSFetchedResultsControllerDelegate>
@property (nonatomic,assign) id<ZSXJDataManagerDelegate> delegate;
#pragma mark -
@property (strong, nonatomic)NSFetchedResultsController *fetchRequestController;
//A class can set this property
@property (strong, nonatomic)NSManagedObjectContext *theManagedObjectContext;

#pragma mark -
#pragma mark Initialize
+ (ZSXJDataManager *)sharedDataManager;
#pragma mark -
//Set entity name and primary key
- (void)setEntity:(NSString *)entityName andPrimaryKey:(NSString *)entityPrimaryKey;
//Configure the result array count
- (void)setBatchSize:(NSInteger)batchSize andLimt:(NSInteger)limitNum;
//Set the Sort Descriptor of a Query
- (NSArray *)queryWithEntity:(NSString *)entityName andDescriptor:(NSSortDescriptor *)descriptor;
//Also can set the Sort Predicate and Sort Descriptor
- (NSArray *)queryWithEntity:(NSString *)entityName andDescriptor:(NSArray *)descriptors andPredicate:(NSPredicate *)sortPredicate;
#pragma mark -
- (BOOL)saveEntities:(NSArray *)entities;
- (BOOL)insertARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey;
//- (BOOL)updateARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey;
- (BOOL)deleteARecord:(NSManagedObject *)aRecord withPrimaryKey:(NSString *)primaryKey;
- (void)synchronizeTheStore;
#pragma mark -
//- (BOOL)clearTheStore;
#pragma mark -

@property (readonly, strong, nonatomic)NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic)NSPersistentStoreCoordinator *persistentStoreCoordinator;
//The dataManager initialize the property itself.
@property (readonly, strong, nonatomic)NSManagedObjectContext *managedObjectContext;
/**
 *  This method is called when Application will terminate 
 *  eg: in the method "applicationWillTerminate" in Appdelegate
 */
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
@end
