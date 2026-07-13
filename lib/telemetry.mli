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

val used_percent : free_blocks:float -> total_blocks:float -> float
val collect : ?path:string -> unit -> t
val to_yojson : t -> Yojson.Basic.t
val to_json_string : t -> string
