//
//  MSDebugHook.h
//  MSDebug
//
//  Created by moses on 2020/6/30.
//  Copyright © 2020 moses. All rights reserved.
//
//  引用自fishhook:https://github.com/facebook/fishhook

#ifdef DEBUG

#ifndef MSDebugHook_h
#define MSDebugHook_h

#include <stdio.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

struct msdebug_rebinding {
    const char *name;
    void *replacement;
    void **replaced;
};

int msdebug_rebind_symbols(struct msdebug_rebinding rebindings[],
                           size_t rebindings_nel);

int msdebug_rebind_symbols_image(void *header,
                                 intptr_t slide,
                                 struct msdebug_rebinding rebindings[],
                                 size_t rebindings_nel);

#ifdef __cplusplus
}
#endif

#endif

#endif
