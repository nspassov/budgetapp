//
//  SpendingHistoryMap.h
//  Budget
//
//  Created by Nikolay Spassov on 16.05.13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewAnnotation : NSObject <MKAnnotation> {
    
	NSString *title;
    NSString *subtitle;
	CLLocationCoordinate2D coordinate;
    NSString *_groupTag;
    
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d;
- (NSString *)groupTag;
- (void)setGroupTag:(NSString *)tag;
- (NSString *)subtitle;
- (void)setSubtitle:(NSString *)text;

@end


@interface SpendingHistoryMap : UIViewController <MKMapViewDelegate>

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView* venueMap;

@end
