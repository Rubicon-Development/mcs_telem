let approx_equal a b = Float.abs (a -. b) < 0.0001
let expect condition message = if not condition then failwith message

let test_topic () =
  let topic = Mcs_telem.Topic.telemetry ~hostname:"mcs01" in
  expect
    (String.equal topic "apex/mcs/mcs01/mcs/mcs01/telemetry")
    "unexpected telemetry topic"
;;

let test_disk_percent () =
  let used = Mcs_telem.Telemetry.used_percent ~free_blocks:25.0 ~total_blocks:100.0 in
  expect (approx_equal used 75.0) "unexpected disk usage percentage";
  let zero = Mcs_telem.Telemetry.used_percent ~free_blocks:0.0 ~total_blocks:0.0 in
  expect (approx_equal zero 0.0) "zero total blocks should produce 0 percent"
;;

let test_payload_json () =
  let telemetry : Mcs_telem.Telemetry.t =
    { hostname = "mcs01"
    ; timestamp = "2026-07-13T12:34:56Z"
    ; device = { os_type = "Unix"; kernel = Some "Linux"; kernel_release = Some "6.0" }
    ; disk = { path = "/"; used_percent = 42.3 }
    }
  in
  let json = Mcs_telem.Telemetry.to_yojson telemetry in
  let open Yojson.Basic.Util in
  expect
    (String.equal (json |> member "hostname" |> to_string) "mcs01")
    "hostname missing from payload";
  expect
    (String.equal (json |> member "disk" |> member "path" |> to_string) "/")
    "disk path missing from payload";
  expect
    (approx_equal (json |> member "disk" |> member "used_percent" |> to_float) 42.3)
    "disk used_percent missing from payload"
;;

let test_config_defaults () =
  Unix.putenv "MCS_TELEM_MQTT_HOST" "broker.local";
  Unix.putenv "MCS_TELEM_MQTT_PORT" "";
  Unix.putenv "MCS_TELEM_INTERVAL_SECONDS" "";
  match Mcs_telem.Config.load () with
  | Error message -> failwith message
  | Ok config ->
    expect (String.equal config.mqtt_host "broker.local") "unexpected mqtt host";
    expect
      (config.mqtt_port = Mcs_telem.Config.default_mqtt_port)
      "unexpected default port";
    expect
      (approx_equal config.interval_seconds Mcs_telem.Config.default_interval_seconds)
      "unexpected default interval"
;;

let () =
  test_topic ();
  test_disk_percent ();
  test_payload_json ();
  test_config_defaults ()
;;
