(*----------------------------------------------------------------------------
  config.ml - Config file parsing
  Copyright (C) 2011 Wojciech Meyer, Jakub Oboza

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

open Yojson.Safe

exception Wrong_type of string
let string = function `String s -> s | _ -> raise (Wrong_type "string")
let int = function `Int i -> i | _ -> raise (Wrong_type "int")

module Client = struct

  let config_filename = "/.indigo.json"
  (* TODO add File.join / Unix.join *)
  let config_file = (Unix.getpwuid (Unix.getuid ())).Unix.pw_dir ^ config_filename
  let default_host = "danmey.org"
  let default_uname = "wojtek"
  let default_port = 1234
  let default_pass = "main"

  let read () =
      let default_config =
	{ LoginData.host = default_host;
	  LoginData.port = default_port;
	  LoginData.login = Some (LoginData.Uname default_uname) } in

      let config = from_file config_file in
      try

	match config with
	    `Assoc assoc  ->
	      begin

		let get_param_safe conversion param_name =
		  conversion (List.assoc param_name assoc) in

		let get_param conversion param_name default_value =
		  try
		    get_param_safe conversion param_name
		  with Wrong_type _ -> default_value in

		let host    = get_param string "host"    default_host       in
		let uname   = get_param string "uname"   default_uname      in
		let port    = get_param int    "port"    default_port       in
		let login =
		  try
		    LoginData.FullLogin
		      { LoginData.pass = get_param_safe string "pass";
			LoginData.uname }
		  with Wrong_type _ -> LoginData.Uname uname in
		{ default_config with
		  LoginData.host;
		  LoginData.port;
		  LoginData.login = Some login } end
	  | _ -> default_config
      with Sys_error _ -> default_config

  let write { LoginData.host;
	      LoginData.port;
	      LoginData.login } =
    let json = `Assoc (["host", `String host;
			"port", `Int port;] @
			  match login with
			    | Some (LoginData.FullLogin
				      { LoginData.uname;
					LoginData.pass; }) ->
			      ["uname", `String uname;
			       "pass", `String pass]
			    | Some (LoginData.Uname uname) ->
			      ["uname", `String uname]
			    | None -> []) in
    to_file config_file json

  let with_profile f = let data = read () in
                       let data = f data  in
                       match data with
                         | Some data -> write data; Some data
                         | None -> data

end


module Server = struct

  let config_filename = "/.indigo-server.json"
  let config_file = (Unix.getpwuid (Unix.getuid ())).Unix.pw_dir ^ config_filename

  let read () =
    let config = from_file config_file in
      match config with
        | `Assoc lst -> List.map (fun (name, pass)-> name, string pass) lst
	| _ -> []

end
