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

module Make (Mqtt : MQTT) = struct
  let client_id ~hostname = "mcs-telem-" ^ hostname

  let credentials (config : Config.t) =
    match config.mqtt_auth with
    | Anonymous -> None
    | Username username -> Mqtt.credentials ~username ~password:None
    | Credentials (username, password) ->
      Mqtt.credentials ~username ~password:(Some password)
  ;;

  let publish_once config telemetry =
    let hostname = telemetry.Telemetry.hostname in
    let topic = Topic.telemetry ~hostname in
    let payload = Telemetry.to_json_string telemetry in
    let id = client_id ~hostname in
    let credentials = credentials config in
    let%lwt client =
      Mqtt.connect ?credentials ~id ~port:config.Config.mqtt_port [ config.mqtt_host ]
    in
    Lwt.finalize
      (fun () -> Mqtt.publish ~topic ~payload ~retain:false ~qos_at_most_once:true client)
      (fun () -> Mqtt.disconnect client)
  ;;
end
