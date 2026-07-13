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
  ; timestamp : string
  ; device : device
  ; disk : disk
  }

external statvfs_blocks : string -> float * float = "mcs_telem_statvfs_blocks"

let used_percent ~free_blocks ~total_blocks =
  if total_blocks <= 0.0
  then 0.0
  else (total_blocks -. free_blocks) /. total_blocks *. 100.0
;;

let timestamp_utc () =
  let tm = Unix.gmtime (Unix.time ()) in
  Printf.sprintf
    "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (tm.tm_year + 1900)
    (tm.tm_mon + 1)
    tm.tm_mday
    tm.tm_hour
    tm.tm_min
    tm.tm_sec
;;

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
  ; timestamp = timestamp_utc ()
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
    [ "hostname", `String t.hostname
    ; "timestamp", `String t.timestamp
    ; ( "device"
      , `Assoc
          [ "os_type", `String t.device.os_type
          ; "kernel", option_string t.device.kernel
          ; "kernel_release", option_string t.device.kernel_release
          ] )
    ; ( "disk"
      , `Assoc [ "path", `String t.disk.path; "used_percent", `Float t.disk.used_percent ]
      )
    ]
;;

let to_json_string t = Yojson.Basic.to_string (to_yojson t)
