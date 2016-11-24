(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

(* Notification demo *)

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-notif"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* Make service available on the client *)
let%client service = ~%service

(* Name for demo menu *)
let%shared name = "Notifications"

(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-notif"

(* Instanciate function Os_notif.Simple for each kind of notification
   you need.
   The key is the resource ID. For example, if you are implementing a
   messaging application, it can be the chatroom ID
   (for example type key = int64).
   In this example, we have only one notification and one resource
   (type key = unit).
*)
module Notif =
  Os_notif.Simple (struct
    type key = unit
    type notification = string
  end)

(* Broadcast message [v] *)
let%server notify v =
  (* Notify all client processes listening on this resource (first paremeter)
     by sending them message v. *)
  Notif.notify (() :  Notif.key) v;
  Lwt.return ()

(* Make [notify] available client-side *)
let%client notify =
  ~%(Eliom_client.server_function [%derive.json : string] notify)

(* Subscribe for notifications via [Notif.listen ()]; produce an alert
   every time the event [e = Notif.client_ev ()] happens *)
let%server listen () =
  Notif.listen ();
  let e : (unit * string) Eliom_react.Down.t = Notif.client_ev () in
  ignore [%client
    ((React.E.map (fun (_, msg) -> Eliom_lib.alert "got %s" msg) ~%e)
     : unit React.E.t)
  ];
  Lwt.return ()

(* Make a text input field that calls [f s] for each [s] submitted *)
let%shared make_form msg f =
  let inp = Eliom_content.Html.D.Raw.input ()
  and btn = Eliom_content.Html.(
    D.button ~a:[D.a_class ["button"]] [D.pcdata msg]
  ) in
  ignore [%client
    ((Lwt.async @@ fun () ->
      let btn = Eliom_content.Html.To_dom.of_element ~%btn
      and inp = Eliom_content.Html.To_dom.of_input ~%inp in
      Lwt_js_events.clicks btn @@ fun _ _ ->
      let v = Js.to_string inp##.value in
      let%lwt () = ~%f v in
      inp##.value := Js.string "";
      Lwt.return ())
     : unit)
  ];
  Eliom_content.Html.D.div [inp; btn]

(* Page for this demo *)
let%server page () =
  let%lwt () = listen () in
  Lwt.return Eliom_content.Html.[
    D.p [D.pcdata "Exchange messages between users.";
         D.br ();
         D.pcdata "Open this page in multiple tabs or browsers.";
         D.br ();
         D.pcdata "Fill in the input form to send a message."];
    make_form "send message" [%client (notify : string -> unit Lwt.t)]
  ]

(* Make page available on client-side *)
let%client page =
  ~%((Eliom_client.server_function [%derive.json: unit] page) :
       (unit,
        [`Div | `P | `Input] Eliom_content.Html.D.elt list)
         Eliom_client.server_function)
