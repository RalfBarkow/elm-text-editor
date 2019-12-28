module Editor exposing (Msg, init, update, view, State, internal)

import Buffer exposing (Buffer)
import Editor.History
import Editor.Model exposing (InternalState)
import Editor.Update
import Editor.View
import Html exposing (Html)
import Position exposing (Position)


type alias Msg =
    Editor.Update.Msg


type State
    = State InternalState

map : (InternalState -> InternalState) -> State -> State
map f (State s) =
    (State (f s))

{-| TEMPORARY!!! -}
internal : State -> InternalState
internal (State s) = s


init : State
init =
    State
        { scrolledLine = 0
        , cursor = Position 0 0
        , window = {first = 0, last = 4}
        , selection = Nothing
        , dragging = False
        , history = Editor.History.empty
        }


update : Buffer -> Msg -> State -> ( State, Buffer, Cmd Msg )
update buffer msg (State state) =
    Editor.Update.update buffer msg state
        |> (\( newState, newBuffer, cmd ) -> ( State newState, newBuffer, cmd ))


view : Buffer -> State -> Html Msg
view buffer (State state) =
    Editor.View.view (Buffer.lines buffer) state
