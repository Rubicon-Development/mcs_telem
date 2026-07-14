type disk =
  { path : string
  ; used_percent : float
  }

type device =
  { os_type : string
  ; kernel : string option
  ; kernel_release : string option
  }

type t =
  { hostname : string
  ; timestamp : int
  ; device : device
  ; disk : disk
  }

external statvfs_blocks : string -> float * float = "mcs_telem_statvfs_blocks"

let used_percent ~free_blocks ~total_blocks =
  if total_blocks <= 0.0
  then 0.0
  else (total_blocks -. free_blocks) /. total_blocks *. 100.0
;;

let timestamp_unix () = int_of_float (Unix.time ())

let read_first_line path =
  try
    let input = open_in path in
    Fun.protect
      ~finally:(fun () -> close_in_noerr input)
      (fun () -> Some (input_line input))
  with
  | Sys_error _ | End_of_file -> None
;;

let device_info () =
  { os_type = Sys.os_type
  ; kernel = read_first_line "/proc/sys/kernel/ostype"
  ; kernel_release = read_first_line "/proc/sys/kernel/osrelease"
  }
;;

let disk_usage path =
  let total_blocks, free_blocks = statvfs_blocks path in
  { path; used_percent = used_percent ~free_blocks ~total_blocks }
;;

let collect ?(path = "/") () =
  { hostname = Unix.gethostname ()
  ; timestamp = timestamp_unix ()
  ; device = device_info ()
  ; disk = disk_usage path
  }
;;

let option_string = function
  | None -> `Null
  | Some value -> `String value
;;

let to_yojson t =
  `Assoc
    [ "timestamp", `Int t.timestamp
    ; "deviceKernelRelease", option_string t.device.kernel_release
    ; "diskUsedPercent", `Float t.disk.used_percent
    ]
;;

let to_json_string t = Yojson.Basic.to_string (to_yojson t)
