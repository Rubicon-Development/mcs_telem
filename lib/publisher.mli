module type MQTT = sig
  type client
  type credentials

  val credentials : username:string -> password:string option -> credentials option

  val connect
    :  ?credentials:credentials
    -> id:string
    -> port:int
    -> string list
    -> client Lwt.t

  val publish
    :  topic:string
    -> payload:string
    -> retain:bool
    -> qos_at_most_once:bool
    -> client
    -> unit Lwt.t

  val disconnect : client -> unit Lwt.t
end

module Make : functor (_ : MQTT) -> sig
  val client_id : hostname:string -> string
  val publish_once : Config.t -> Telemetry.t -> unit Lwt.t
end
