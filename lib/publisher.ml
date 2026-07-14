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

module Make (Mqtt : MQTT) = struct
  type client = Mqtt.client

  let client_id ~hostname = "mcs-telem-" ^ hostname

  let credentials (config : Config.t) =
    match config.mqtt_auth with
    | Anonymous -> None
    | Username username -> Mqtt.credentials ~username ~password:None
    | Credentials (username, password) ->
      Mqtt.credentials ~username ~password:(Some password)
  ;;

  let connect config ~hostname =
    let id = client_id ~hostname in
    let credentials = credentials config in
    Mqtt.connect
      ?credentials
      ?tls_ca:config.Config.mqtt_tls_ca
      ~id
      ~port:config.Config.mqtt_port
      [ config.mqtt_host ]
  ;;

  let publish client telemetry =
    let topic = Topic.telemetry ~hostname:telemetry.Telemetry.hostname in
    let payload = Telemetry.to_json_string telemetry in
    Mqtt.publish ~topic ~payload ~retain:false ~qos_at_most_once:true client
  ;;
end
