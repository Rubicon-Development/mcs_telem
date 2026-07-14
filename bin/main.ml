module Mqtt_adapter = struct
  type client = Mqtt_client.t
  type credentials = Mqtt_client.credentials

  let credentials ~username ~password =
    match password with
    | None -> Some (Mqtt_client.Username username)
    | Some password -> Some (Mqtt_client.Credentials (username, password))
  ;;

  let connect ?credentials ?tls_ca ~id ~port hosts =
    Mqtt_client.connect ?credentials ?tls_ca ~id ~port hosts
  ;;

  let publish ~topic ~payload ~retain ~qos_at_most_once client =
    let qos =
      if qos_at_most_once then Mqtt_client.Atmost_once else Mqtt_client.Atleast_once
    in
    Mqtt_client.publish ~qos ~retain ~topic payload client
  ;;

  let disconnect = Mqtt_client.disconnect
end

module App = Mcs_telem.Daemon.Make (Mqtt_adapter)

let setup_logs () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Info)
;;

let () =
  setup_logs ();
  match Mcs_telem.Config.load () with
  | Error message ->
    Logs.err (fun m -> m "%s" message);
    exit 1
  | Ok config -> Lwt_main.run (App.run config)
;;
