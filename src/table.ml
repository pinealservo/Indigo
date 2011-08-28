(*----------------------------------------------------------------------------
  table.ml - Main definiton of table
  Copyright (C) 2011 Wojciech Meyer 

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


module Make(G : Board.GRAPHICS_BACKEND) = struct
  module Board = Board.Make(G)
  module Element = Board.Element
  type t = { boards: Board.t list }

  let rec create () = { boards = [] }
  and add canvas tile =
    { canvas with boards = tile :: canvas.boards; }

  and draw canvas gc =
    List.iter (Element.draw gc) canvas.boards

  and button_pressed canvas ~x ~y =
    { canvas with boards = List.map (fun t -> Element.button_pressed t ~x ~y) canvas.boards }

  and button_released canvas ~x ~y =
    { canvas with boards = List.map (fun t -> Element.button_released t ~x ~y) canvas.boards }

  and motion canvas ~x ~y =
    { canvas with boards = List.map (fun t -> Element.motion t ~x ~y) canvas.boards }

  and print c = List.iter (fun t -> Element.print t; print_endline ""; flush stdout) c.boards
    
  and dragged canvas = List.exists Element.dragged canvas.boards

  and replace_item canvas id ~item =
    let rec loop = function
      | [] -> []
      | i :: xs ->
        if id = i.Board.id then
          item :: loop xs
        else
          i :: loop xs
    in
    { canvas with boards = loop canvas.boards }

  and find_item canvas id =
    List.find (fun t -> t.Board.id = id) canvas.boards
    
  and move_item canvas id ~x ~y =
    let item = find_item canvas id in
    replace_item canvas id ~item:{item with Board.pos=(x,y) }

end
