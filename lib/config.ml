type mqtt_auth =
  | Anonymous
  | Username of string
  | Credentials of string * string

type t =
  { mqtt_host : string
  ; mqtt_port : int
  ; mqtt_auth : mqtt_auth
  ; mqtt_tls_ca : string option
  ; interval_seconds : float
  }

let default_mqtt_port = 1883
let default_interval_seconds = 60.0
let default_tls_ca = "/etc/ssl/certs/ca-certificates.crt"
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

let parse_bool name value =
  match String.lowercase_ascii (String.trim value) with
  | "1" | "true" | "yes" | "on" -> Ok true
  | "0" | "false" | "no" | "off" -> Ok false
  | _ -> Error (Printf.sprintf "%s must be true or false" name)
;;

let tls_enabled mqtt_port =
  match getenv "MCS_TELEM_MQTT_TLS" with
  | None | Some "" -> Ok (mqtt_port = 8883)
  | Some value -> parse_bool "MCS_TELEM_MQTT_TLS" value
;;

let tls_ca_path enabled =
  if not enabled
  then Ok None
  else (
    match getenv "MCS_TELEM_MQTT_TLS_CA", getenv "SSL_CERT_FILE" with
    | Some path, _ when String.trim path <> "" -> Ok (Some path)
    | _, Some path when String.trim path <> "" -> Ok (Some path)
    | _ when Sys.file_exists default_tls_ca -> Ok (Some default_tls_ca)
    | _ ->
      Error
        (Printf.sprintf
           "TLS is enabled but no CA file was found; set MCS_TELEM_MQTT_TLS_CA"))
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
    let* tls_enabled = tls_enabled mqtt_port in
    let* mqtt_tls_ca = tls_ca_path tls_enabled in
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
    Ok { mqtt_host; mqtt_port; mqtt_auth; mqtt_tls_ca; interval_seconds }
;;
