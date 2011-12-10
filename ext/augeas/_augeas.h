/*
 * augeas.h: internal headers for Augeas Ruby bindings
 *
 * Copyright (C) 2008-2011 Red Hat Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
 */

#include <ruby.h>

#ifndef _AUGEAS_H_
#define _AUGEAS_H_

#define StringValueCStrOrNull(v)                \
    NIL_P(v) ? NULL : StringValueCStr(v)

/* memstream support from Augeas internal.h */
struct memstream {
    FILE   *stream;
    char   *buf;
    size_t size;
};

int __aug_init_memstream(struct memstream *ms);
int __aug_close_memstream(struct memstream *ms);

#endif

/*
 * Local variables:
 *  indent-tabs-mode: nil
 *  c-indent-level: 4
 *  c-basic-offset: 4
 *  tab-width: 4
 * End:
 */
