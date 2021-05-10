//
//  TrackedAmounts.h
//  Budget
//
//  Created by Nikolay Spassov on 07.05.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrackedAmounts : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, retain) NSString * dateOccurs;
@property (nonatomic, retain) NSNumber * day;
@property (nonatomic, retain) NSNumber * month;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSDate * when;
@property (nonatomic, retain) NSString * venue;
@property (nonatomic, retain) NSDecimalNumber * latitude;
@property (nonatomic, retain) NSDecimalNumber * longitude;

@end
