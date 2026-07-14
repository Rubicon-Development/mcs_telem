module type MQTT = sig
  type client
  type credentials

  val credentials : username:string -> password:string option -> credentials option

  val connect
    :  ?credentials:credentials
    -> ?tls_ca:string
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

module Make : functor (Mqtt : MQTT) -> sig
  type client = Mqtt.client

  val client_id : hostname:string -> string
  val connect : Config.t -> hostname:string -> client Lwt.t
  val publish : client -> Telemetry.t -> unit Lwt.t
end
