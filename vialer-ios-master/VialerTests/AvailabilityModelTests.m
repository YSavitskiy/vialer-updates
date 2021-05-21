//
//  AvailabilityModelTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"
#import <OCMock/OCMock.h>
#import "Vialer-Swift.h"
@import XCTest;

@interface AvailabilityModelTests : XCTestCase
@property (strong, nonatomic) AvailabilityModel *availabilityModel;
@property (strong, nonatomic) NSDictionary *givenSelectedDestinations;
@end

@interface AvailabilityModel()
- (NSString *)storeNewAvialibityInSUD:(NSDictionary *)option;
- (NSArray *)createDestinations:(NSArray*) userDestinations withDestinationType:(NSString*)destinationType withSelectedDestination:(NSDictionary*)selectedDestination;
@end

NSString * const SystemUserAvailabilityDescriptionKey = @"availabilityDescription";
NSString * const SystemUserAvailabilityPhoneNumberKey = @"phonenumber";
NSString * const AvailabilityModelSelected = @"availabilitySelected";
NSString * const AvailabilityModelDestinationType = @"availabilityType";
NSString * const AvailabilityModelId = @"availabilityId";

static NSString * const AvailabilityModelSelectedUserDestinationFixedKey = @"fixeddestination";
static NSString * const AvailabilityModelSelectedUserDestinationPhoneaccountKey = @"phoneaccount";
static NSString * const AvailabilityModelDescriptionKey = @"description";
static NSString * const AvailabilityModelSelectedUserDestinationIdKey = @"id";
static NSString * const AvailabilityModelInternalNumbersKey = @"internal_number";

@implementation AvailabilityModelTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (AvailabilityModel *)availabilityModel {
    if (!_availabilityModel) {
        _availabilityModel = [[AvailabilityModel alloc] init];
    }
    return _availabilityModel;
}

- (NSDictionary *)givenSelectedDestinations {
    if (!_givenSelectedDestinations) {
        _givenSelectedDestinations = @{
                                       AvailabilityModelSelectedUserDestinationPhoneaccountKey: @242,
                                       AvailabilityModelSelectedUserDestinationFixedKey: @342,
                                       };;
    }
    return _givenSelectedDestinations;
}

- (void)testCreateDestinations {
    // Given
    NSArray *givenUserDestinations = @[
                                        @{
                                            AvailabilityModelDescriptionKey: @"Test User",
                                            AvailabilityModelSelectedUserDestinationIdKey: @242,
                                            AvailabilityModelInternalNumbersKey: @42,
                                        }
                                    ];
    NSString *givenDestinationType = AvailabilityModelSelectedUserDestinationPhoneaccountKey;

    // When
    NSArray *outputDestinations = [self.availabilityModel createDestinations:givenUserDestinations withDestinationType:givenDestinationType withSelectedDestination:self.givenSelectedDestinations];

    // Then
    NSArray *expectedDestinations = @[
                                      @{
                                          SystemUserAvailabilityDescriptionKey: @"Test User",
                                          AvailabilityModelId: @242,
                                          AvailabilityModelSelected: @1,
                                          AvailabilityModelDestinationType: givenDestinationType,
                                          SystemUserAvailabilityPhoneNumberKey: @42,
                                        }
                                      ];
    XCTAssertEqualObjects(outputDestinations, expectedDestinations, @"Outputs did not match");
}

- (void)testCreateDestinationsWithStringsForIds {
    // Given
    NSArray *givenUserDestinations = @[
                                       @{
                                           AvailabilityModelDescriptionKey: @"Test User",
                                           AvailabilityModelSelectedUserDestinationIdKey: @"242",
                                           AvailabilityModelInternalNumbersKey: @42,
                                           }
                                       ];
    NSString *givenDestinationType = AvailabilityModelSelectedUserDestinationPhoneaccountKey;

    // When
    NSArray *outputDestinations = [self.availabilityModel createDestinations:givenUserDestinations withDestinationType:givenDestinationType withSelectedDestination:self.givenSelectedDestinations];

    // Then
    NSArray *expectedDestinations = @[
                                      @{
                                          SystemUserAvailabilityDescriptionKey: @"Test User",
                                          AvailabilityModelId: @"242",
                                          AvailabilityModelSelected: @1,
                                          AvailabilityModelDestinationType: givenDestinationType,
                                          SystemUserAvailabilityPhoneNumberKey: @42,
                                          }
                                      ];
    XCTAssertEqualObjects(outputDestinations, expectedDestinations, @"Outputs did not match");
}

- (void)testCreateDestinationsWithFixedDestinations {
    // Given
    NSArray *givenUserDestinations = @[
                                       @{
                                           AvailabilityModelDescriptionKey: @"Test User",
                                           AvailabilityModelSelectedUserDestinationIdKey: @342,
                                           SystemUserAvailabilityPhoneNumberKey: @"42",
                                           }
                                       ];
    NSString *givenDestinationType = AvailabilityModelSelectedUserDestinationFixedKey;

    // When
    NSArray *outputDestinations = [self.availabilityModel createDestinations:givenUserDestinations withDestinationType:givenDestinationType withSelectedDestination:self.givenSelectedDestinations];

    // Then
    NSArray *expectedDestinations = @[
                                      @{
                                          SystemUserAvailabilityDescriptionKey: @"Test User",
                                          AvailabilityModelId: @342,
                                          AvailabilityModelSelected: @1,
                                          AvailabilityModelDestinationType: givenDestinationType,
                                          SystemUserAvailabilityPhoneNumberKey: @42,
                                          }
                                      ];
    XCTAssertEqualObjects(outputDestinations, expectedDestinations, @"Outputs did not match");
}

@end
