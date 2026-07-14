module Make : functor (_ : Publisher.MQTT) -> sig
  val run : Config.t -> unit Lwt.t
end
