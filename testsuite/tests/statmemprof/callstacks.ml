(* TEST
   flags = "-g -w -5"
   * bytecode
*)

open Gc.Memprof

let alloc_list_literal () =
  ignore (Sys.opaque_identity [Sys.opaque_identity 1])

let alloc_pair () =
  ignore (Sys.opaque_identity (Sys.opaque_identity 1, Sys.opaque_identity 2))

type record = { a : int; b : int }
let alloc_record () =
  ignore (Sys.opaque_identity
            {a = Sys.opaque_identity 1; b = Sys.opaque_identity 2})

let alloc_some () =
  ignore (Sys.opaque_identity (Some (Sys.opaque_identity 2)))

let alloc_array_literal () =
  ignore (Sys.opaque_identity [|Sys.opaque_identity 1|])

let alloc_float_array_literal () =
  ignore (Sys.opaque_identity
            [|Sys.opaque_identity 1.; Sys.opaque_identity 2.|])

let[@inline never] do_alloc_unknown_array_literal x =
  Sys.opaque_identity [|x|]
let alloc_unknown_array_literal () =
  ignore (Sys.opaque_identity (do_alloc_unknown_array_literal 1.))

let alloc_small_array () =
  ignore (Sys.opaque_identity (Array.make 10 (Sys.opaque_identity 1)))

let alloc_large_array () =
  ignore (Sys.opaque_identity (Array.make 100000 (Sys.opaque_identity 1)))

let alloc_closure () =
  let x = Sys.opaque_identity 1 in
  ignore (Sys.opaque_identity (fun () -> x))

let floatarray = [| 1. |]
let getfloatfield () =
  ignore (Sys.opaque_identity (floatarray.(0)))

let marshalled =
  Marshal.to_string [Sys.opaque_identity 1] []
let alloc_unmarshal () =
  ignore (Sys.opaque_identity
            (Marshal.from_string (Sys.opaque_identity marshalled) 0))

let alloc_ref () =
  ignore (Sys.opaque_identity (ref (Sys.opaque_identity 1)))

let fl = 1.
let alloc_boxedfloat () =
  ignore (Sys.opaque_identity
            (Sys.opaque_identity fl *. Sys.opaque_identity fl))

let allocators =
  [alloc_list_literal; alloc_pair; alloc_record; alloc_some;
   alloc_array_literal; alloc_float_array_literal; alloc_unknown_array_literal;
   alloc_small_array; alloc_large_array; alloc_closure;
   getfloatfield; alloc_unmarshal; alloc_ref; alloc_boxedfloat]

let test alloc =
  Printf.printf "-----------\n%!";
  let callstack = ref None in
  start ~callstack_size:10
        ~minor_alloc_callback:(fun info ->
           callstack := Some info.callstack;
           None
        )
        ~major_alloc_callback:(fun info ->
           callstack := Some info.callstack;
           None
        )
        ~sampling_rate:1. ();
  alloc ();
  stop ();
  match !callstack with
  | None -> assert false
  | Some cs -> Printexc.print_raw_backtrace stdout cs

let () =
  List.iter test allocators
