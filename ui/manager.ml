module type UI = sig end
type t = { mutable screens : Screen.t list
         ; mutable current_screen : Screen.t option
         ; pending_events : unit Event.t Queue.t
         ; mutable event_receivers : EventReceiver.t list }

let manager = { screens = []
              ; current_screen = None
              ; pending_events = Queue.create ()
              ; event_receivers = [] }

let current_screen () =
  match manager.current_screen with
  | None -> failwith "No screen"
  | Some screen -> screen

let open_screen name =
  let screen = Screen.create name in
  manager.screens <- screen :: manager.screens;
  match manager.current_screen with
  | None -> manager.current_screen <- Some screen
  | Some _ -> ()

let open_window ~x ~y ~w ~h ?parent name =
  let screen = current_screen() in
  let window = Window.create () in
  Window.(window.rel_x <- x;
          window.rel_y <- y;
          window.width <- w;
          window.height <- h;
          Screen.add_window screen window)
