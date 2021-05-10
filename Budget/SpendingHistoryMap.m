//
//  SpendingHistoryMap.m
//  Budget
//
//  Created by Nikolay Spassov on 16.05.13.
//
//

#import "SpendingHistoryMap.h"
#import "BudgetAppDelegate.h"
#import <CoreData/CoreData.h>
#import "TrackedAmounts.h"

@implementation MapViewAnnotation

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize coordinate = _coordinate;

- (id)initWithTitle:(NSString *)ttl andCoordinate:(CLLocationCoordinate2D)c2d {
	_title = ttl;
	_coordinate = c2d;
	return self;
}
- (NSString *)subtitle{
    return _subtitle;
}

- (void)setSubtitle:(NSString *)text{
    _subtitle = text;
}
- (NSString *)groupTag{
    return _groupTag;
}

- (void)setGroupTag:(NSString *)tag{
    _groupTag = tag;
}
@end


@interface SpendingHistoryMap () {
    NSString* _mainCurrency;
}

@end

@implementation SpendingHistoryMap

@synthesize managedObjectContext = _managedObjectContext;
@synthesize venueMap = _venueMap;


- (void)putLocationsOnMap
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[NSLocale currentLocale]];
    _mainCurrency = [formatter currencyCode];
    NSUserDefaults* lastState = [NSUserDefaults standardUserDefaults];
    if([lastState valueForKey:@"mainCurrency"]) {
        _mainCurrency = [lastState valueForKey:@"mainCurrency"];
    }

    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:2];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TrackedAmounts" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"amount < 0 AND currency == '%@'", _mainCurrency]];
    [fetchRequest setPredicate:filter];
    NSExpressionDescription* ex = [[NSExpressionDescription alloc] init];
    [ex setExpression:[NSExpression expressionWithFormat:@"@sum.amount"]];
    [ex setExpressionResultType:NSDecimalAttributeType];
    [ex setName:@"summedamount"];
    
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"venue", @"latitude", @"longitude", ex, nil]];
    [fetchRequest setPropertiesToGroupBy:[NSArray arrayWithObjects:@"venue", @"latitude", @"longitude", nil]];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    NSError* error;
    NSArray* buf = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error) {
        NSLog(@"%@", error);
    }
//    NSLog(@"%@", buf);
    for(TrackedAmounts* a in buf) {
        CLLocationCoordinate2D loc;
        loc.latitude = [[a valueForKey:@"latitude"] doubleValue];
        loc.longitude = [[a valueForKey:@"longitude"] doubleValue];
        MapViewAnnotation* ann = nil;
        if([a valueForKey:@"venue"]) {
            ann = [[MapViewAnnotation alloc] initWithTitle:[a valueForKey:@"venue"] andCoordinate:loc];
            ann.subtitle = [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[a valueForKey:@"summedamount"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency];
        }
        else {
            ann = [[MapViewAnnotation alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:[[a valueForKey:@"summedamount"] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]]], _mainCurrency] andCoordinate:loc];
        }
        [self.venueMap addAnnotation:ann];
    }
}


//- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation{
//    MKAnnotationView *annotationView;
//    
//    // if it's a cluster
//    if ([annotation isKindOfClass:[OCAnnotation class]]) {
//        
//        OCAnnotation *clusterAnnotation = (OCAnnotation *)annotation;
//        
//        annotationView = (MKAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:@"ClusterView"];
//        if (!annotationView) {
//            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ClusterView"];
//            annotationView.canShowCallout = YES;
//            annotationView.centerOffset = CGPointMake(0, -20);
//        }
//        //calculate cluster region
//        CLLocationDistance clusterRadius = self.venueMap.region.span.longitudeDelta * self.venueMap.clusterSize * 111000 / 2.0f; //static circle size of cluster
//        //CLLocationDistance clusterRadius = mapView.region.span.longitudeDelta/log(mapView.region.span.longitudeDelta*mapView.region.span.longitudeDelta) * log(pow([clusterAnnotation.annotationsInCluster count], 4)) * mapView.clusterSize * 50000; //circle size based on number of annotations in cluster
//        
//        MKCircle *circle = [MKCircle circleWithCenterCoordinate:clusterAnnotation.coordinate radius:clusterRadius * cos([annotation coordinate].latitude * M_PI / 180.0)];
//        [circle setTitle:@"background"];
//        [self.venueMap addOverlay:circle];
//        
//        MKCircle *circleLine = [MKCircle circleWithCenterCoordinate:clusterAnnotation.coordinate radius:clusterRadius * cos([annotation coordinate].latitude * M_PI / 180.0)];
//        [circleLine setTitle:@"line"];
//        [self.venueMap addOverlay:circleLine];
//        
//        // set title
//        clusterAnnotation.title = @"Cluster";
//        clusterAnnotation.subtitle = [NSString stringWithFormat:@"Containing annotations: %d", [clusterAnnotation.annotationsInCluster count]];
//        
//        // set its image
//        annotationView.image = [UIImage imageNamed:@"regular.png"];
//        
//        // change pin image for group
//        if (self.venueMap.clusterByGroupTag) {
//            annotationView.image = [UIImage imageNamed:@"07-map-marker"];
//            clusterAnnotation.title = clusterAnnotation.groupTag;
//        }
//    }
//    // If it's a single annotation
//    else if([annotation isKindOfClass:[MapViewAnnotation class]]){
//        MapViewAnnotation *singleAnnotation = (MapViewAnnotation *)annotation;
//        annotationView = (MKAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:@"singleAnnotationView"];
//        if (!annotationView) {
//            annotationView = [[MKAnnotationView alloc] initWithAnnotation:singleAnnotation reuseIdentifier:@"singleAnnotationView"];
//            annotationView.canShowCallout = YES;
//            annotationView.centerOffset = CGPointMake(0, -20);
//        }
//        annotationView.image = [UIImage imageNamed:@"07-map-marker"];
//        singleAnnotation.title = singleAnnotation.groupTag;
//    }
//    // Error
//    else{
//        annotationView = (MKPinAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:@"errorAnnotationView"];
//        if (!annotationView) {
//            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"errorAnnotationView"];
//            annotationView.canShowCallout = NO;
//            ((MKPinAnnotationView *)annotationView).pinColor = MKPinAnnotationColorRed;
//        }
//    }
//    
//    return annotationView;
//}
//
//- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
//    MKCircle *circle = overlay;
//    MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
//    
//    if ([circle.title isEqualToString:@"background"])
//    {
//        circleView.fillColor = [UIColor yellowColor];
//        circleView.alpha = 0.25;
//    }
//    else if ([circle.title isEqualToString:@"helper"])
//    {
//        circleView.fillColor = [UIColor redColor];
//        circleView.alpha = 0.25;
//    }
//    else
//    {
//        circleView.strokeColor = [UIColor blackColor];
//        circleView.lineWidth = 0.5;
//    }
//    
//    return circleView;
//}
//
//- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated{
////    [self.venueMap removeOverlays:self.venueMap.overlays];
////    [self.venueMap doClustering];
//}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#ifndef DEBUG
//    [Flurry logEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title} timed:YES];
#endif

    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0xaa/255.f green:0x00/255.f blue:0xaa/255.f alpha:1]];
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifndef DEBUG
//    [Flurry endTimedEvent:@"Viewing Screen" withParameters:@{@"Screen Name":self.title}];
#endif
    [super viewWillDisappear:animated];
}

#define kDEFAULTCLUSTERSIZE 0.2

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.managedObjectContext = ((BudgetAppDelegate*)[[UIApplication sharedApplication] delegate]).managedObjectContext;
//    self.venueMap.delegate = self;
//    self.venueMap.clusterSize = kDEFAULTCLUSTERSIZE;
//    self.venueMap.clusteringMethod = OCClusteringMethodBubble;
//    [self.venueMap setClusteringEnabled:NO];

    [self putLocationsOnMap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
