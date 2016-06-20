#import "ManagedJastor.h"
#import "ManagedJastorRuntimeHelper.h"

@implementation ManagedJastor

@synthesize objectId;
static NSString *idPropertyName = @"id";
static NSString *idPropertyNameOnObject = @"objectId";

Class mnsDictionaryClass;
Class mnsArrayClass;

- (void)initializeFieldsWithDictionary:(NSDictionary *)dictionary {
    if (!mnsDictionaryClass) mnsDictionaryClass = [NSDictionary class];
    if (!mnsArrayClass) mnsArrayClass = [NSArray class];
    
    for (NSString *key in [ManagedJastorRuntimeHelper propertyNames:[self class]]) {
        id value = [dictionary valueForKey:key];
        Class propertyClass = [ManagedJastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
        
        if (value == [NSNull null] || value == nil) continue;
        
        // handle dictionary
        if ([value isKindOfClass:mnsDictionaryClass]) {
            Class klass = [ManagedJastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
            NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(klass) inManagedObjectContext:self.managedObjectContext];
            ManagedJastor *managedObject = (ManagedJastor*) [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
            [managedObject initializeFieldsWithDictionary:value];
            value = managedObject;
        }
        // handle array
        else if ([value isKindOfClass:mnsArrayClass]) {
            Class arrayItemType = [[self class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@_class", key])];
            
            NSMutableSet *childObjects = [NSMutableSet setWithCapacity:[value count]];
            
            for (id child in value) {
                if ([[child class] isSubclassOfClass:mnsDictionaryClass]) {
                    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(arrayItemType) inManagedObjectContext:self.managedObjectContext];
                    ManagedJastor *managedObject = (ManagedJastor*) [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                    [managedObject initializeFieldsWithDictionary:child];
                    [childObjects addObject:managedObject];
                } else {

                [childObjects addObject:child];
                }
            }
            
            SEL sel = NSSelectorFromString([NSString stringWithFormat:@"add%@%@:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]]);
            [self performSelector:sel withObject:childObjects];
            
            continue;
        }else if(propertyClass == [NSDate class] && [value isKindOfClass:[NSNumber class]]){
            //Timestamp conversion
            [self setValue:[NSDate dateWithTimeIntervalSince1970:[value longLongValue]/1000] forKey:key];
        }else{
            // handle all others
            [self setValue:value forKey:key];
        }
    }
    
    id objectIdValue;
    if ((objectIdValue = [dictionary objectForKey:idPropertyName]) && objectIdValue != [NSNull null]) {
        if (![objectIdValue isKindOfClass:[NSString class]]) {
            objectIdValue = [NSString stringWithFormat:@"%@", objectIdValue];
        }
        [self setValue:objectIdValue forKey:idPropertyNameOnObject];
    }

    return; 
}

- (void)dealloc {
    self.objectId = nil;
}

- (void)encodeWithCoder:(NSCoder*)encoder {
    [encoder encodeObject:self.objectId forKey:idPropertyNameOnObject];
    for (NSString *key in [ManagedJastorRuntimeHelper propertyNames:[self class]]) {
        [encoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        [self setValue:[decoder decodeObjectForKey:idPropertyNameOnObject] forKey:idPropertyNameOnObject];
        
        for (NSString *key in [ManagedJastorRuntimeHelper propertyNames:[self class]]) {
            id value = [decoder decodeObjectForKey:key];
            if (value != [NSNull null] && value != nil) {
                [self setValue:value forKey:key];
            }
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    if (self.objectId) [dic setObject:self.objectId forKey:idPropertyNameOnObject];
    
    for (NSString *key in [ManagedJastorRuntimeHelper propertyNames:[self class]]) {
        id value = [self valueForKey:key];
        if (value != nil) [dic setObject:value forKey:key];
    }
    
    return [NSString stringWithFormat:@"#<%@: id = %@ %@>", [self class], self.objectId, [dic description]];
}

@end
