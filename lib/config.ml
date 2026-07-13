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

let default_mqtt_port = 1883
let default_interval_seconds = 60.0
let getenv name = Sys.getenv_opt name

let require_env name =
  match getenv name with
  | Some value when String.trim value <> "" -> Ok value
  | _ -> Error (Printf.sprintf "missing required environment variable %s" name)
;;

let parse_int name value =
  match int_of_string_opt value with
  | Some parsed when parsed > 0 -> Ok parsed
  | _ -> Error (Printf.sprintf "%s must be a positive integer" name)
;;

let parse_float name value =
  match float_of_string_opt value with
  | Some parsed when parsed > 0.0 -> Ok parsed
  | _ -> Error (Printf.sprintf "%s must be a positive number" name)
;;

let load () =
  match require_env "MCS_TELEM_MQTT_HOST" with
  | Error _ as err -> err
  | Ok mqtt_host ->
    let ( let* ) = Result.bind in
    let* mqtt_port =
      match getenv "MCS_TELEM_MQTT_PORT" with
      | None | Some "" -> Ok default_mqtt_port
      | Some value -> parse_int "MCS_TELEM_MQTT_PORT" value
    in
    let* interval_seconds =
      match getenv "MCS_TELEM_INTERVAL_SECONDS" with
      | None | Some "" -> Ok default_interval_seconds
      | Some value -> parse_float "MCS_TELEM_INTERVAL_SECONDS" value
    in
    let mqtt_auth =
      match getenv "MCS_TELEM_MQTT_USERNAME", getenv "MCS_TELEM_MQTT_PASSWORD" with
      | Some username, Some password
        when String.trim username <> "" && String.trim password <> "" ->
        Credentials (username, password)
      | Some username, _ when String.trim username <> "" -> Username username
      | _ -> Anonymous
    in
    Ok { mqtt_host; mqtt_port; mqtt_auth; interval_seconds }
;;
