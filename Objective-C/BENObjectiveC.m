// BENObjectiveC.m
#import <Foundation/Foundation.h>

static NSString *mimeForPath(NSString *path) {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([ext isEqualToString:@"png"])  return @"image/png";
    if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) return @"image/jpeg";
    if ([ext isEqualToString:@"webp"]) return @"image/webp";
    if ([ext isEqualToString:@"gif"])  return @"image/gif";
    if ([ext isEqualToString:@"bmp"])  return @"image/bmp";
    if ([ext isEqualToString:@"tif"] || [ext isEqualToString:@"tiff"]) return @"image/tiff";
    if ([ext isEqualToString:@"heic"]) return @"image/heic";
    return @"application/octet-stream";
}

static void background_removal(NSString *src, NSString *dst, NSString *apiKey) {
    // Read file
    NSData *fileData = [NSData dataWithContentsOfFile:src];
    if (!fileData) { NSLog(@"❌ Could not read %@", src); return; }

    NSString *filename = [src lastPathComponent];
    NSString *ctype    = mimeForPath(src);
    NSString *boundary = [NSString stringWithFormat:@"----%@", [[NSUUID UUID] UUIDString]];
    NSString *CRLF     = @"\r\n";

    // Build multipart body
    NSMutableData *body = [NSMutableData data];

    NSMutableString *head = [NSMutableString string];
    [head appendFormat:@"--%@%@", boundary, CRLF];
    [head appendFormat:@"Content-Disposition: form-data; name=\"image_file\"; filename=\"%@\"%@", filename, CRLF];
    [head appendFormat:@"Content-Type: %@%@%@", ctype, CRLF, CRLF];
    [body appendData:[head dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];

    NSString *tail = [NSString stringWithFormat:@"--%@--%@",
                      boundary, CRLF];
    [body appendData:[tail dataUsingEncoding:NSUTF8StringEncoding]];

    // Prepare request
    NSURL *url = [NSURL URLWithString:@"https://api.backgrounderase.net/v2"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
forHTTPHeaderField:@"Content-Type"];
    [req setValue:apiKey forHTTPHeaderField:@"x-api-key"];
    [req setValue:[NSString stringWithFormat:@"%tu", body.length] forHTTPHeaderField:@"Content-Length"];
    req.HTTPBody = body;

    // Send (synchronously using a semaphore for simplicity)
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSData *respData = nil;
    __block NSHTTPURLResponse *resp = nil;
    __block NSError *err = nil;

    [[[NSURLSession sharedSession] dataTaskWithRequest:req
                                    completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        respData = d; resp = (NSHTTPURLResponse *)r; err = e;
        dispatch_semaphore_signal(sema);
    }] resume];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    if (err) { NSLog(@"❌ Request error: %@", err.localizedDescription); return; }

    if (resp.statusCode == 200 && respData.length > 0) {
        if ([respData writeToFile:dst atomically:YES]) {
            NSLog(@"✅ Saved: %@", dst);
        } else {
            NSLog(@"❌ Failed to write %@", dst);
        }
    } else {
        NSString *reason = [NSHTTPURLResponse localizedStringForStatusCode:resp.statusCode];
        NSString *bodyStr = respData ? [[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding] : @"";
        NSLog(@"❌ %ld %@ %@", (long)resp.statusCode, reason, bodyStr ?: @"");
    }
}

// Example CLI-style usage
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 4) {
            NSLog(@"Usage: BENObjectiveC <input> <output.png> <YOUR_API_KEY>");
            return 1;
        }
        NSString *src = [NSString stringWithUTF8String:argv[1]];
        NSString *dst = [NSString stringWithUTF8String:argv[2]];
        NSString *key = [NSString stringWithUTF8String:argv[3]];
        background_removal(src, dst, key);
    }
    return 0;
}
