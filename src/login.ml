(*----------------------------------------------------------------------------
  login.ml - Login form
  Copyright (C) 2011 Wojciech Meyer 

  (contains some code and reworked version of `input_widget' in gToolbox.ml 
  from Lablgtk)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
  --------------------------------------------------------------------------*)

type t = { host:string; port:int; uname:string }

let mOk = "Ok"
let mCancel = "Cancel"

let ldestroy f w = w # destroy (); f ()
let ldestroy' w = ldestroy (fun () -> None) w

let input_widget_ex ~widget ~event ~bind_ok ~expand ?(actions=[])
    ?(accept=(mOk, ldestroy')) ?(cancel=(mCancel, ldestroy'))
    ~title message =

  let retour = ref None in

  let ok_lb, f_ok = accept in
  let cancel_lb, f_cancel = cancel in

  let window = GWindow.dialog ~title ~modal:true () in

  let _ = window#connect#destroy ~callback: GMain.Main.quit in

  let main_box = window#vbox in
  let hbox_boutons = window#action_area in

  let vbox_saisie = GPack.vbox ~packing: (main_box#pack ~expand: true) () in
  
  ignore (GMisc.label ~text:message ~packing:(vbox_saisie#pack ~padding:3) ());

  vbox_saisie#pack widget ~expand ~padding: 3;
  let actions = [accept] @ actions @ [cancel] in
  let wb_ok :: _ = List.map (fun (name, cb) ->
    let b = GButton.button ~label: name
      ~packing: 
      (hbox_boutons#pack ~expand: true ~padding: 3) () in
    let _ = b # connect # clicked (fun () -> retour := cb window) in
    b) actions  in

  wb_ok#grab_default ();

  (* the enter key is linked to the ok action *)
  (* the escape key is linked to the cancel action *)
  event#connect#key_press ~callback:
    begin fun ev -> 
      if GdkEvent.Key.keyval ev = GdkKeysyms._Return && bind_ok then retour := f_ok window;
      if GdkEvent.Key.keyval ev = GdkKeysyms._Escape then retour := f_cancel window;
      false
    end;

  widget#misc#grab_focus ();
  window#show ();
  GMain.Main.main ();

  !retour


open Pcre
let rexp n r s =
  try
    let rex = regexp  r in
    let ss = exec ~rex s in
    Some (get_substring ss n)
  with Not_found -> None

(* Taken from http://stackoverflow.com/questions/106179/regular-expression-to-match-hostname-or-ip-address *)
let validIpAddressRegex = "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])";;
let validHostnameRegex = "(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\\-]*[A-Za-z0-9])"
let uname_chars = "[a-zA-Z0-9_\\-]"
let port_chars = "[0-9]"  
let hostname_regex = Printf.sprintf "(%s)|(%s)" validHostnameRegex validIpAddressRegex
let login_regex = Printf.sprintf "^((%s+)@)?(%s)(:(%s+))?$" uname_chars hostname_regex port_chars

let parse_login str =
  rexp 2 login_regex str,
  rexp 4 login_regex str,
  rexp 8 login_regex str,
  rexp 13 login_regex str

let err msg =
  let d = GWindow.message_dialog ~message:msg
    ~message_type:`ERROR
    ~modal:true
    ~buttons:GWindow.Buttons.close () in
  d # connect # response ~callback:(fun _ -> d # destroy());
  ignore(d # show())

let validate_login text =
  let uname, host, ip, port = parse_login text in
  let host = match host, ip with 
    | (Some h, None) -> Some h  
    | (None , Some h) ->  Some h 
    | _ -> None in
  let err what = err (Printf.sprintf "%s needs to be specified or is incorrect!" what) in
  match host with
    | None -> err "Host or IP"; None
    | Some host -> begin match port with
        | None -> err "Port"; None
        | Some port -> Some (uname, host, int_of_string port) end
  

let rec login_widget ~title ?ok ?cancel ?(text="") message =
  let vbox = GPack.vbox () in
  let we_chaine = GEdit.entry ~text ~packing:vbox#add () in
  if text <> "" then
    we_chaine#select_region 0 (we_chaine#text_length);
  let do_login w text =
    match validate_login text with
      | Some (uname, host, port) -> w # destroy (); begin 
        let data = { uname = ""; host; port } in
        match uname with
          | Some uname -> Some { data with uname }
          | None -> uname_widget data end
      | None -> None in
    input_widget_ex ~widget:vbox#coerce ~event:we_chaine#event
      ~bind_ok:true
      ~expand: false
      ~title
      ~accept:(mOk, fun w -> do_login w we_chaine#text)
      ~actions:["Clipboard login",
                begin fun w ->
                  let clipboard = GtkBase.Clipboard.get Gdk.Atom.clipboard in
                  let text = GtkBase.Clipboard.wait_for_text clipboard in
                  match text with
                    | Some text -> do_login w text
                  | None -> err "Clipboard contents need to be text!"; None
              end] message


and uname_widget data =
  let vbox = GPack.vbox () in
  let we_chaine = GEdit.entry ~text:(Printf.sprintf "%s:%d" data.host data.port) ~packing:vbox#add () in
  match GToolbox.input_string
    ~title:"Your private login details"
    ~ok:"Login"
    ~text:"" "aka" with
    | Some uname -> Some { data with uname }
    | None -> uname_widget data

let create k =
  ignore (GMain.init ());
  login_widget
    ~title:"Paste your login details or click paste"
    ~ok:"Login"
    ~text:"danmey.org:1234" "INDIGO";;

create "11";;