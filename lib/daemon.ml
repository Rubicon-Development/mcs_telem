module Make (Mqtt : Publisher.MQTT) = struct
  module Publisher = Publisher.Make (Mqtt)

  let rec run config =
    let telemetry = Telemetry.collect () in
    let%lwt () =
      Lwt.catch
        (fun () -> Publisher.publish_once config telemetry)
        (fun exn ->
           Logs.err (fun m ->
             m "failed to publish telemetry: %s" (Printexc.to_string exn));
           Lwt.return_unit)
    in
    let%lwt () = Lwt_unix.sleep config.Config.interval_seconds in
    run config
  ;;
end
