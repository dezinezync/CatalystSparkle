//
//  CheckWifi.m
//  Yeti
//
//  Created by Nikhil Nigade on 30/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "CheckWifi.h"

// IMPL from https://stackoverflow.com/a/40305705/1387258

#import <ifaddrs.h>
#import <arpa/inet.h>

BOOL CheckWiFi() {
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    BOOL hasWifi = NO;
    
    int err = getifaddrs(&interfaces);
    if(err == 0) {
        
        temp_addr = interfaces;
        
        while(temp_addr) {
            
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                
                __unused struct sockaddr_in *addr = (struct sockaddr_in *)temp_addr->ifa_addr;
                
                if(memcmp(temp_addr->ifa_name, "en", 2) == 0) {
                    hasWifi = YES;
                    break;
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return hasWifi;
}
