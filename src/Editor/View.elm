module Editor.View exposing (view)

import Char
import Editor.Keymap
import Editor.Model exposing (InternalState)
import Editor.Update exposing (Msg(..))
import Html exposing (Attribute, Html, div, span, text)
import Html.Attributes as Attribute exposing (class, classList)
import Html.Events as Event
import Json.Decode as Decode
import Position exposing (Position)
import Window exposing(Window)


name : String
name =
    "elm-editor"


selected : Position -> Maybe Position -> Position -> Bool
selected cursor maybeSelection char =
    maybeSelection
        |> Maybe.map (\selection -> Position.between cursor selection char)
        |> Maybe.withDefault False


{-| The non-breaking space character will not get whitespace-collapsed like a
regular space.
-}
nonBreakingSpace : Char
nonBreakingSpace =
    Char.fromCode 160


ensureNonBreakingSpace : Char -> Char
ensureNonBreakingSpace char =
    if char == ' ' then
        nonBreakingSpace

    else
        char


withTrue : a -> ( a, Bool )
withTrue a =
    ( a, True )


captureOnMouseDown : Msg -> Attribute Msg
captureOnMouseDown msg =
    Event.stopPropagationOn
        "mousedown"
        (Decode.map withTrue (Decode.succeed msg))


captureOnMouseOver : Msg -> Attribute Msg
captureOnMouseOver msg =
    Event.stopPropagationOn
        "mouseover"
        (Decode.map withTrue (Decode.succeed msg))


character : Position -> Maybe Position -> Position -> Char -> Html Msg
character cursor selection position char =
    span
        [ classList
            [ ( name ++ "-line__character", True )
            , ( name ++ "-line__character--has-cursor", cursor == position )
            , ( name ++ "-line__character--selected"
              , selected cursor selection position
              )
            ]
        , captureOnMouseDown (MouseDown position)
        , captureOnMouseOver (MouseOver position)
        ]
        [ text <| String.fromChar <| ensureNonBreakingSpace char
        , if cursor == position then
            span [ class <| name ++ "-cursor" ] [ text " " ]

          else
            text ""
        ]


line : Position -> Maybe Position -> Int -> String -> Html Msg
line cursor selection number content =
    let
        length =
            String.length content

        endPosition =
            { line = number, column = length }
    in
    div
        [ class <| name ++ "-line"
        , captureOnMouseDown (MouseDown endPosition)
        , captureOnMouseOver (MouseOver endPosition)
        ]
    <|
        List.concat
            [ [ span
                    [ class <| name ++ "-line__gutter-padding"
                    , captureOnMouseDown (MouseDown { line = number, column = 0 })
                    , captureOnMouseOver (MouseOver { line = number, column = 0 })
                    ]
                    [ text <| String.fromChar nonBreakingSpace ]
              ]
            , List.indexedMap
                (Position number >> character cursor selection)
                (String.toList content)
            , if cursor.line == number && cursor.column >= length then
                [ span
                    [ class <| name ++ "-line__character"
                    , class <| name ++ "-line__character--has-cursor"
                    ]
                    [ text " "
                    , span [ class <| name ++ "-cursor" ] [ text " " ]
                    ]
                ]

              else
                []
            ]


onTripleClick : msg -> Attribute msg
onTripleClick msg =
    Event.on
        "click"
        (Decode.field "detail" Decode.int
            |> Decode.andThen
                (\detail ->
                    if detail >= 3 then
                        Decode.succeed msg

                    else
                        Decode.fail ""
                )
        )


lineNumber : Int -> Html Msg
lineNumber number =
    span
        [ class <| name ++ "-line-number"
        , captureOnMouseDown (MouseDown { line = number, column = 0 })
        , captureOnMouseOver (MouseOver { line = number, column = 0 })
        ]
        [ text <| String.fromInt (number + 0) ]


gutter : Position -> Window -> Html Msg
gutter cursor window =
    let
        first = max 0 (cursor.line - window.last )
        last = first + (window.last - window.first)
    in
    div [ class <| name ++ "-gutter" ] <|
        List.map lineNumber (List.range first last)


linesContainer : List (Html Msg) -> Html Msg
linesContainer =
    div [ class <| name ++ "-lines" ]


view : List String -> InternalState -> Html Msg
view lines state =
    div
        [ class <| name ++ "-container"
        , Event.preventDefaultOn
            "keydown"
            (Decode.map withTrue Editor.Keymap.decoder)
        , Event.onMouseUp MouseUp
        , Event.onDoubleClick SelectGroup
        , onTripleClick SelectLine
        , Attribute.tabindex 0
        ]
        [ gutter state.cursor state.window -- List.length lines
        , linesContainer <|
            List.indexedMap (line state.cursor state.selection) (Window.select state.cursor state.window lines)
        ]
