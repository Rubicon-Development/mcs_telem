module Make (Mqtt : Publisher.MQTT) = struct
  module Publisher = Publisher.Make (Mqtt)

  let log_failure action exn =
    Logs.err (fun m -> m "failed to %s: %s" action (Printexc.to_string exn))
  ;;

  let rec connect_and_publish config =
    let telemetry = Telemetry.collect () in
    Lwt.catch
      (fun () ->
         let%lwt client = Publisher.connect config ~hostname:telemetry.hostname in
         let%lwt () = Publisher.publish client telemetry in
         publish_loop config client)
      (fun exn ->
         log_failure "connect or publish telemetry" exn;
         let%lwt () = Lwt_unix.sleep config.Config.interval_seconds in
         connect_and_publish config)

  and publish_loop config client =
    let%lwt () = Lwt_unix.sleep config.Config.interval_seconds in
    let telemetry = Telemetry.collect () in
    let%lwt () =
      Lwt.catch
        (fun () -> Publisher.publish client telemetry)
        (fun exn ->
           log_failure "publish telemetry" exn;
           connect_and_publish config)
    in
    publish_loop config client
  ;;

  let run config = connect_and_publish config
end
