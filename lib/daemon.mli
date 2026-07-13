module Make : functor (_ : Publisher.MQTT) -> sig
  val run : Config.t -> 'a Lwt.t
end
