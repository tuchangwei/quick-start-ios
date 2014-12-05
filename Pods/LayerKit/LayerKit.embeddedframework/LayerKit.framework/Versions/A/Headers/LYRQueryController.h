//
//  LYRQueryController.h
//  LayerKit
//
//  Created by Blake Watters on 11/05/14.
//  Copyright (c) 2014 Layer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LYRQuery;
@protocol LYRQueryControllerDelegate, LYRQueryable;

/**
 @abstract The `LYRQueryController` class provides an interface for driving the user interface of a `UITableView` or `UICollectionView` directly from a `LYRQuery` object.
 */
@interface LYRQueryController : NSObject

///--------------------------
/// @name Accessing the Query
///--------------------------

/**
 @abstract Returns the query of the receiver.
 */
@property (nonatomic, readonly) LYRQuery *query;

///-----------------------------
/// @name Accessing the Delegate
///-----------------------------

/**
 @abstract Accesses the receiver's delegate.
 */
@property (nonatomic, weak) id<LYRQueryControllerDelegate> delegate;

///-----------------------------------------
/// @name Counting Objects in the Result Set
///-----------------------------------------

/**
 @abstract Returns the number of sections in the result set.
 @return The number of sections in the receiver's result set.
 */
- (NSUInteger)numberOfSections;

/**
 @abstract Returns the number of objects in the given section in the result set.
 @param section The section to return the number of objects for.
 @return The number of objects in the specified section of the result set.
 */
- (NSUInteger)numberOfObjectsInSection:(NSUInteger)section;

/**
 @abstract Returns the total number of objects in the result set.
 @return The number of objects in the result set.
 */
- (NSUInteger)count;

///----------------------------------------
/// @name Accessing Objects and Index Paths
///----------------------------------------

/**
 @abstract Returns the object for the given index path from the result set.
 @param indexPath The index path for the object to retrieve.
 @return The object at the specified index or `nil` if none could be found.
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

/**
 @abstract Returns the index path for the given object in the result set.
 @param object The object to retrieve the index path for.
 @return The index path for the given object or `nil` if it does not exist in the result set.
 */
- (NSIndexPath *)indexPathForObject:(id<LYRQueryable>)object;

///--------------------------
/// @name Executing the Query
///--------------------------

/**
 @abstract Executes the query and loads a result set into the receiver.
 @param error A pointer to an error object that upon failure is set to an error object that describes 
 the nature of the failure.
 @return A Boolean value that indicates if execution of the query was successful.
 */
- (BOOL)execute:(NSError **)error;

@end

/**
 @abstract The `LYRQueryControllerChangeType` is an enumerated value that specifies the type of change occurring in the
 result set of an `LYRQueryController` object.
 */
typedef NS_ENUM(NSUInteger, LYRQueryControllerChangeType) {
    /**
     @abstract An object is being inserted into the result set.
     */
    LYRQueryControllerChangeTypeInsert 	= 1,
    
    /**
     @abstract An object is being deleted from the result set.
     */
    LYRQueryControllerChangeTypeDelete 	= 2,
    
    /**
     @abstract An object is being moved within the result set.
     */
    LYRQueryControllerChangeTypeMove 	= 3,
    
    /**
     @abstract An object is being deleted from the result set.
     */
    LYRQueryControllerChangeTypeUpdate 	= 4
};

/**
 @abstract The `LYRQueryControllerDelegate` protocol is adopted by objects that wish to act as the delegate for a query controller.
 */
@protocol LYRQueryControllerDelegate <NSObject>

@optional

/**
 @abstract Tells the delegate that the result set of query controller is about to change.
 @param The query controller that is changing.
 */
- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController;

/**
 @abstract Tells the delegate that the result set of query controller has changed.
 @param The query controller that has changed.
 */
- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController;

/**
 @abstract Tells the delegate that a particular object in the result set of query controller has changed.
 @param The query controller that is changing.
 @param object The object that has changed in the result set.
 @param indexPath The index path of the object or `nil` if the change is an insert.
 @param type An enumerated value that specifies the type of change that is occurring.
 @param newIndexPath The new index path for the object or `nil` if the change is an update or delete.
 */
- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

@end
