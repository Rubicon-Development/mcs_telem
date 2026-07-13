#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <errno.h>
#include <string.h>
#include <sys/statvfs.h>

CAMLprim value mcs_telem_statvfs_blocks(value path_v) {
    CAMLparam1(path_v);
    CAMLlocal1(result);

    struct statvfs stats;
    if (statvfs(String_val(path_v), &stats) != 0) {
        caml_failwith(strerror(errno));
    }

    result = caml_alloc_tuple(2);
    Store_field(result, 0, caml_copy_double((double)stats.f_blocks));
    Store_field(result, 1, caml_copy_double((double)stats.f_bfree));

    CAMLreturn(result);
}
