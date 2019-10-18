#import <XCTest/XCTest.h>

@interface WPDateTimeHelpers : NSObject

+ (NSString *)userFriendlyStringDateFromDate:(NSDate *)date;

+ (NSString *)userFriendlyStringTimeFromDate:(NSDate *)date;

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;

+ (void)setForcedLocaleIdentifier:(NSString *)localeIdentifier;

@end

@interface WPDateTimeHelpersTest : XCTestCase

@end

@implementation WPDateTimeHelpersTest

- (void)tearDown {
    [WPDateTimeHelpers setForcedLocaleIdentifier:nil];
}

- (void)testStringFromTimeInterval
{
    NSTimeInterval timeInterval = 120;
    NSString * result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"02:00", result);

    timeInterval = 119.4;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"02:00", result);

    timeInterval = 119.5;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"02:00", result);

    timeInterval = 0.1;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"00:01", result);

    timeInterval = 30;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"00:30", result);

    timeInterval = 60;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"01:00", result);

    timeInterval = 65;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"01:05", result);

    timeInterval = 3600;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"01:00:00", result);

    timeInterval = 3605;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"01:00:05", result);

    timeInterval = 3667;
    result = [WPDateTimeHelpers stringFromTimeInterval:timeInterval];
    XCTAssertEqualObjects(@"01:01:07", result);
}

- (void)testUserFriendlyStringDateFromDate {

    XCTAssertThrows([WPDateTimeHelpers userFriendlyStringDateFromDate:nil]);

    [WPDateTimeHelpers setForcedLocaleIdentifier:@"en_us"];
    NSDate *now = [NSDate new];
    XCTAssertEqualObjects([WPDateTimeHelpers userFriendlyStringDateFromDate:now], @"Today");

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *yesterday = [calendar dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:now options:0];
    XCTAssertEqualObjects([WPDateTimeHelpers userFriendlyStringDateFromDate:yesterday], @"Yesterday");

    [WPDateTimeHelpers setForcedLocaleIdentifier:@"pt_pt"];
    XCTAssertEqualObjects([WPDateTimeHelpers userFriendlyStringDateFromDate:now], @"Hoje");
    XCTAssertEqualObjects([WPDateTimeHelpers userFriendlyStringDateFromDate:yesterday], @"Ontem");
}

@end

