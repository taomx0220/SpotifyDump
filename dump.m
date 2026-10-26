// dump.m
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <string.h>

__attribute__((constructor))
static void dump_init(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSArray *keys = @[@"repeat", @"loop", @"skip", @"playeroptions"];
        NSMutableString *out = [NSMutableString string];
        unsigned int n = 0;
        Class *classes = objc_copyClassList(&n);
        for (unsigned int i = 0; i < n; i++) {
            Class c = classes[i];
            const char *img = class_getImageName(c);
            if (!img || !strstr(img, ".app/")) continue;   // 只看 App 自带的代码
            NSString *cn = NSStringFromClass(c);
            for (int pass = 0; pass < 2; pass++) {
                Class k = pass ? object_getClass(c) : c;   // 0=实例方法 1=类方法
                unsigned int mc = 0;
                Method *ms = class_copyMethodList(k, &mc);
                for (unsigned int j = 0; j < mc; j++) {
                    NSString *sel = NSStringFromSelector(method_getName(ms[j]));
                    NSString *low = [[cn stringByAppendingString:sel] lowercaseString];
                    for (NSString *key in keys) {
                        if ([low containsString:key]) {
                            [out appendFormat:@"%c[%@ %@] %s\n", pass ? '+' : '-', cn, sel,
                             method_getTypeEncoding(ms[j]) ?: ""];
                            break;
                        }
                    }
                }
                free(ms);
            }
        }
        free(classes);
        NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        [out writeToFile:[dir stringByAppendingPathComponent:@"spotify_dump.txt"]
              atomically:YES encoding:NSUTF8StringEncoding error:nil];
    });
}
