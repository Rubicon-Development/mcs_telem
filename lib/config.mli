type mqtt_auth =
  | Anonymous
  | Username of string
  | Credentials of string * string

type t =
  { mqtt_host : string
  ; mqtt_port : int
  ; mqtt_auth : mqtt_auth
  ; interval_seconds : float
  }

val default_mqtt_port : int
val default_interval_seconds : float
val load : unit -> (t, string) result
