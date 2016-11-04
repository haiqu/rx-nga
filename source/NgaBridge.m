//
//  NgaBridge.m
//  RETRO12
//
//  Created by Charles Childers on 11/3/16.
//  Copyright © 2016 Charles Childers. All rights reserved.
//

#import "NgaBridge.h"

@implementation NgaBridge
#define TIB 1471

CELL Dictionary, Heap, Compiler;
CELL notfound;
#define D_OFFSET_LINK  0
#define D_OFFSET_XT    1
#define D_OFFSET_CLASS 2
#define D_OFFSET_NAME  3
int d_link(CELL dt) {
    return dt + D_OFFSET_LINK;
}
int d_xt(CELL dt) {
    return dt + D_OFFSET_XT;
}
int d_class(CELL dt) {
    return dt + D_OFFSET_CLASS;
}
int d_name(CELL dt) {
    return dt + D_OFFSET_NAME;
}

- (CELL)pop {
    sp--;
    return data[sp + 1];
}

- (void)push:(CELL)value {
    sp++;
    data[sp] = value;
    
}

- (void)injectString:(NSString *)str into:(int)buffer {
    int m = (int)[str length];
    int i = 0;
    while (m > 0) {
        memory[buffer + i] = (CELL)[str characterAtIndex:i];
        memory[buffer + i + 1] = 0;
        m--; i++;
    }
}

- (NSString *)extractStringAt:(int)at {
    NSMutableString *Output = [[NSMutableString alloc] initWithString:@""];
    CELL starting = at;
    while(memory[starting])
        [Output appendFormat:@"%c", (char)memory[starting++]];
    return Output;
}


- (int)getHeaderFor:(NSString *)name in:(CELL)dict {
    CELL dt = 0;
    CELL i = dict;
    NSString *dname;
    while (memory[i] != 0 && i != 0) {
        dname = [self extractStringAt:d_name(i)];
        if ([dname isEqualToString:name]) {
            dt = i;
            i = 0;
        } else {
            i = memory[i];
        }
    }
    return dt;
}

- (int)getExecutionTokenFor:(NSString *)name in:(CELL)dict {
    return memory[d_xt([self getHeaderFor:name in:dict])];
}

- (int)getClassHandlerFor:(NSString *)name in:(CELL)dict {
    return memory[d_class([self getHeaderFor:name in:dict])];
}

- (NSString *)executeFunctionAt:(int)cell {
    NSMutableString *Output = [[NSMutableString alloc] initWithString:@""];
    CELL opcode;
    rp = 1;
    ip = cell;
    while (ip < IMAGE_SIZE) {
        if (ip == notfound) {
            [Output appendFormat:@"\nerr:notfound - %@\n", [self extractStringAt:TIB]];
        }
        opcode = memory[ip];
        if (ngaValidatePackedOpcodes(opcode) != 0) {
            ngaProcessPackedOpcodes(opcode);
        } else if (opcode >= 0 && opcode < 27) {
            ngaProcessOpcode(opcode);
        } else {
            if (opcode == 1000) {
                [Output appendFormat:@"%c", data[sp]];
                sp--;
            } else {
                [Output appendFormat:@"\n\nFATAL ERROR\nInvalid instruction %d at %d\n\n", opcode, ip];
                ip = IMAGE_SIZE;
            }
        }
        ip++;
        if (rp == 0)
            ip = IMAGE_SIZE;
    }
    return Output;
}

- (void)update {
    Dictionary = memory[2];
    Heap = memory[3];
    Compiler = [self getExecutionTokenFor:@"Compiler" in:Dictionary];
    notfound = [self getExecutionTokenFor:@"err:notfound" in:Dictionary];
}

- (NSString *)evaluateToken:(NSString *)s {
    if ([s length] == 0)
        return @"";
    [self update];
    [self injectString:s into:TIB];
    [self push:TIB];
    return [self executeFunctionAt:[self getExecutionTokenFor:@"interpret" in:Dictionary]];
}

- (NSArray *)stackValues {
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (int i = 1; i <= sp; i++) {
        [values addObject:[NSNumber numberWithLong:data[i]]];
    }
    return values;
}

@end

