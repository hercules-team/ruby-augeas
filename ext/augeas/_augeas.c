/*
 * augeas.c: Ruby bindings for augeas
 *
 * Copyright (C) 2008 Red Hat Inc.
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
 *
 * Author: Bryan Kearney <bkearney@redhat.com>
 */
#include <ruby.h>
#include <augeas.h>

/*
 * call-seq:
 *   get(PATH) -> String
 *
 * Lookup the value associated with PATH
 */
VALUE augeas_get(VALUE m, VALUE path) {
    const char *cpath = StringValuePtr(path) ;
    const char *value = aug_get(cpath) ;
    VALUE returnValue = Qnil ;
    if (value != NULL) {
        returnValue = rb_str_new(value, strlen(value)) ;
    }
    return returnValue ;
}

/*
 * call-seq:
 *   exists(PATH) -> boolean
 *
 * Return true if there is an entry for this path, false otherwise 
 */
VALUE augeas_exists(VALUE m, VALUE path) {
    const char *cpath = StringValuePtr(path) ;
    int callValue = aug_exists(cpath) ;
    VALUE returnValue ;

    if (callValue == 1)
        returnValue = Qtrue ;
    else
        returnValue = Qfalse ;

    return returnValue ;
}

/*
 * call-seq:
 *   set(PATH, VALUE) -> boolean
 *
 * Set the value associated with PATH to VALUE. VALUE is copied into the
 * internal data structure. Intermediate entries are created if they don't
 * exist.
 */
VALUE augeas_set(VALUE m, VALUE path, VALUE value) {
    const char *cpath = StringValuePtr(path) ;
    const char *cvalue = StringValuePtr(value) ;

    int callValue = aug_set(cpath, cvalue) ;
    VALUE returnValue ;

    if (callValue == 0)
        returnValue = Qtrue ;
    else
        returnValue = Qfalse ;

    return returnValue ;
}

/*
 * call-seq:
 *   insert(PATH, SIBLING) -> int
 *
 * Make PATH a SIBLING of PATH by inserting it directly before SIBLING.
 */
VALUE augeas_insert(VALUE m, VALUE path, VALUE sibling) {
    const char *cpath = StringValuePtr(path) ;
    const char *csibling = StringValuePtr(sibling) ;

    int callValue = aug_insert(cpath, csibling) ;
    return INT2FIX(callValue) ;
}

/*
 * call-seq:
 *   rm(PATH) -> int
 *
 * Remove path and all its children. Returns the number of entries removed
 */
VALUE augeas_rm(VALUE m, VALUE path, VALUE sibling) {
    const char *cpath = StringValuePtr(path) ;

    int callValue = aug_rm(cpath) ;
    return INT2FIX(callValue) ;
}

/*
 * call-seq:
 *   ls(PATH) -> an_array
 *
 * Return a list of the direct children of PATH in CHILDREN, which is
 * allocated and must be freed by the caller, including the strings it
 * contains. If CHILDREN is NULL, nothing is allocated and only the number
 * of children is returned. Returns -1 on error, or the total number of
 * children of PATH.
 */
VALUE augeas_ls(VALUE m, VALUE path) {

    int cnt = 0 ;
    const char **paths ;
    char *cpath = StringValuePtr(path) ;
    cnt = aug_ls(cpath, &paths) ;
    VALUE returnArray = rb_ary_new() ;
    if (cnt > 0) {
        int x ;
        for (x=0; x < cnt; x++) {
            rb_ary_push(returnArray, rb_str_new(paths[x], strlen(paths[x]))) ;
            free((void*)paths[x]) ;
        }
        free (paths) ;
    }

    return returnArray ;
}


/*
 * call-seq:
 *       match(PATH, SIZE) -> an_array
 *
 * Return the first SIZE paths that match PATTERN, which must be
 * preallocated to hold at least SIZE entries. If no size is provided,
 * then all matches are returned
 *
 * The PATTERN is passed to fnmatch(3) verbatim, and FNM_FILE_NAME is not set,
 * so that '*' does not match a '/'
 */
VALUE augeas_match(int argc, VALUE *argv, VALUE obj) {

    if (argc == 0)
        rb_raise(rb_eArgError, "wrong number of arguments (0 for 1)") ;

    const char *cpattern = StringValuePtr(argv[0])  ;

    // figure out the size
    int csize = 0 ;
    if (argc > 1) {
        csize = NUM2INT(argv[1]) ;
    }
    else  {
        // pre-fetch to get the count if no size was provided
        csize = aug_match(cpattern, NULL, 0) ;
    }

    // grab memory and make the call
    const char **matches = calloc(csize, sizeof(char *));
    int cnt = aug_match(cpattern, matches, csize) ;

    // Process the return value
    VALUE returnArray = rb_ary_new() ;
    if (cnt > 0) {
        int x ;
        for (x=0; x < csize; x++) {
            rb_ary_push(returnArray, rb_str_new(matches[x], strlen(matches[x]))) ;
            free((void*)matches[x]) ;
        }
        free (matches) ;
    }

    return returnArray ;
}

/*
 * call-seq:
 *       save() -> boolean
 *
 * Write all pending changes to disk
 */
VALUE augeas_save(VALUE m) {
    int callValue = aug_save() ;
    VALUE returnValue ;

    if (callValue == 0)
        returnValue = Qtrue ;
    else
        returnValue = Qfalse ;

    return returnValue ;
}

VALUE augeas_init(VALUE m) {
    aug_init() ;
}

void Init__augeas() {

    /* Define the ruby class */
    VALUE augeasclass = rb_define_class("Augeas",rb_cObject) ;

    /* Define the methods */
    rb_define_protected_method(augeasclass, "aug_init", augeas_init, 0) ;
    rb_define_method(augeasclass, "get", augeas_get, 1) ;
    rb_define_method(augeasclass, "exists", augeas_exists, 1) ;
    rb_define_method(augeasclass, "insert", augeas_insert, 2) ;
    rb_define_method(augeasclass, "rm", augeas_rm, 1) ;
    rb_define_method(augeasclass, "ls", augeas_ls, 1) ;
    rb_define_method(augeasclass, "match", augeas_match, -1) ;
    rb_define_method(augeasclass, "save", augeas_save, 0) ;
    rb_define_method(augeasclass, "set", augeas_set, 2) ;
}

/*
 * Local variables:
 *  indent-tabs-mode: nil
 *  c-indent-level: 4
 *  c-basic-offset: 4
 *  tab-width: 4
 * End:
 */
