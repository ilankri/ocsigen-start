(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

[%%shared
  open Eliom_content.Html
  open Eliom_content.Html.D
]


(* Timepicker demo *)

(* Service for this demo *)
let%server service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["demo-timepicker"])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* Make service available on the client *)
let%client service = ~%service

let%server s, f = Eliom_shared.React.S.create None

let%client action (h, m) = ~%f (Some (h, m)); Lwt.return ()

let%shared string_of_time = function
  | Some (h, m) ->
    Printf.sprintf "You clicked on %d:%d" h m
  | None ->
    ""

let%server time_as_string () : string Eliom_shared.React.S.t =
  Eliom_shared.React.S.map [%shared string_of_time] s

let%server time_reactive () = Lwt.return @@ time_as_string ()

let%client time_reactive =
  ~%(Eliom_client.server_function [%derive.json: unit] time_reactive)

(* Name for demo menu *)
let%shared name = "TimePicker"

(* Class for the page containing this demo (for internal use) *)
let%shared page_class = "os-page-demo-timepicker"

(* Page for this demo *)
let%shared page () =
  let time_picker, _, back_f = Ot_time_picker.make
      ~h24:true
      ~action:[%client action]
      ()
  in
  let button = Eliom_content.Html.D.button [pcdata "back to hours"] in
  ignore
    [%client
      (Lwt.async (fun () ->
         Lwt_js_events.clicks
           (To_dom.of_element ~%button)
           (fun _ _ ->
              ~%back_f ();
              Lwt.return ()))
       : _)
    ];
  let%lwt tr = time_reactive () in
  Lwt.return
    [
      p [pcdata "This page shows the time picker."];
      div [time_picker];
      p [Eliom_content.Html.R.pcdata tr];
      div [button]
    ]
