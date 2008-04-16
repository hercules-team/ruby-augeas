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

static VALUE c_augeas;

static augeas_t aug_handle(VALUE s) {
    augeas_t aug;

    /* This is the same as Data_Get_Struct without having to know
       that augeas_t is a pointer to something and what that something is
       */
    Check_Type(s, T_DATA);
    aug = DATA_PTR(s);
    if (aug == NULL) {
        rb_raise(rb_eSystemCallError, "Failed to retrieve connection");
    }
    return aug;
}

static void augeas_close(void *aug) {
    aug_close(aug);
}

/*
 * call-seq:
 *   get(PATH) -> String
 *
 * Lookup the value associated with PATH
 */
VALUE augeas_get(VALUE s, VALUE path) {
    augeas_t aug = aug_handle(s);
    const char *cpath = StringValuePtr(path) ;
    const char *value = aug_get(aug, cpath) ;
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
VALUE augeas_exists(VALUE s, VALUE path) {
    augeas_t aug = aug_handle(s);
    const char *cpath = StringValuePtr(path) ;
    int callValue = aug_exists(aug, cpath) ;
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
VALUE augeas_set(VALUE s, VALUE path, VALUE value) {
    augeas_t aug = aug_handle(s);
    const char *cpath = StringValuePtr(path) ;
    const char *cvalue = StringValuePtr(value) ;

    int callValue = aug_set(aug, cpath, cvalue) ;
    VALUE returnValue ;

    if (callValue == 0)
        returnValue = Qtrue ;
    else
        returnValue = Qfalse ;

    return returnValue ;
}

/*
 * call-seq:
 *   insert(PATH, LABEL, BEFORE) -> int
 *
 * Make LABEL a sibling of PATH by inserting it directly before or after PATH.
 * The boolean BEFORE determines if LABEL is inserted before or after PATH.
 */
VALUE augeas_insert(VALUE s, VALUE path, VALUE label, VALUE before) {
    augeas_t aug = aug_handle(s);
    const char *cpath = StringValuePtr(path) ;
    const char *clabel = StringValuePtr(label) ;

    int callValue = aug_insert(aug, cpath, clabel, RTEST(before));
    return INT2FIX(callValue) ;
}

/*
 * call-seq:
 *   rm(PATH) -> int
 *
 * Remove path and all its children. Returns the number of entries removed
 */
VALUE augeas_rm(VALUE s, VALUE path, VALUE sibling) {
    augeas_t aug = aug_handle(s);
    const char *cpath = StringValuePtr(path) ;

    int callValue = aug_rm(aug, cpath) ;
    return INT2FIX(callValue) ;
}

/*
 * call-seq:
 *       match(PATH) -> an_array
 *
 * Return all the paths that match the path expression PATH as an aray of
 * strings.
 */
VALUE augeas_match(VALUE s, VALUE p) {
    augeas_t aug = aug_handle(s);
    const char *path = StringValuePtr(p);
    char **matches = NULL;
    int cnt, i;

    cnt = aug_match(aug, path, &matches) ;
    if (cnt < 0)
        rb_raise(rb_eSystemCallError, "Matching path expression '%s' failed",
                 path);

    VALUE result = rb_ary_new();
    for (i = 0; i < cnt; i++) {
        rb_ary_push(result, rb_str_new(matches[i], strlen(matches[i])));
        free(matches[i]) ;
    }
    free (matches) ;

    return result ;
}

/*
 * call-seq:
 *       save() -> boolean
 *
 * Write all pending changes to disk
 */
VALUE augeas_save(VALUE s) {
    augeas_t aug = aug_handle(s);
    int callValue = aug_save(aug) ;
    VALUE returnValue ;

    if (callValue == 0)
        returnValue = Qtrue ;
    else
        returnValue = Qfalse ;

    return returnValue ;
}

/*
 * call-seq:
 *       open(ROOT, LOADPATH, FLAGS) -> Augeas
 *
 * Create a new instance and return it
 */
VALUE augeas_init(VALUE m, VALUE r, VALUE l, VALUE f) {
    unsigned int flags = NUM2UINT(f);
    const char *root = (r == Qnil) ? NULL : StringValueCStr(r);
    const char *loadpath = (l == Qnil) ? NULL : StringValueCStr(l);
    augeas_t aug = NULL;

    aug = aug_init(root, loadpath, flags);
    if (aug == NULL) {
        rb_raise(rb_eSystemCallError, "Failed to initialize Augeas");
    }
    return Data_Wrap_Struct(c_augeas, NULL, augeas_close, aug);
}

void Init__augeas() {

    /* Define the ruby class */
    c_augeas = rb_define_class("Augeas", rb_cObject) ;

    /* Constants for enum aug_flags */
#define DEF_AUG_FLAG(name) \
    rb_define_const(c_augeas, #name, INT2NUM(AUG_##name))
    DEF_AUG_FLAG(NONE);
    DEF_AUG_FLAG(SAVE_BACKUP);
    DEF_AUG_FLAG(SAVE_NEWFILE);
    DEF_AUG_FLAG(TYPE_CHECK);
#undef DEF_AUG_FLAG

    /* Define the methods */
    rb_define_singleton_method(c_augeas, "open", augeas_init, 3);
    rb_define_method(c_augeas, "get", augeas_get, 1);
    rb_define_method(c_augeas, "exists", augeas_exists, 1);
    rb_define_method(c_augeas, "insert", augeas_insert, 3);
    rb_define_method(c_augeas, "rm", augeas_rm, 1);
    rb_define_method(c_augeas, "match", augeas_match, 1);
    rb_define_method(c_augeas, "save", augeas_save, 0);
    rb_define_method(c_augeas, "set", augeas_set, 2);
}

/*
 * Local variables:
 *  indent-tabs-mode: nil
 *  c-indent-level: 4
 *  c-basic-offset: 4
 *  tab-width: 4
 * End:
 */
