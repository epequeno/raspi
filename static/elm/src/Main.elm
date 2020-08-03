module Main exposing (Model, Msg, init, subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, colspan)
import Http
import Json.Decode as Decode exposing (Decoder, errorToString, int, list, string)
import Json.Decode.Pipeline exposing (required)
import ParseInt exposing (parseInt)
import Task
import Time exposing (Month(..), millisToPosix, toDay, toHour, toMinute, toMonth, toYear, utc)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl text ->
            "Bad Url: " ++ text

        Http.Timeout ->
            "Http Timeout"

        Http.NetworkError ->
            "Network Error, maybe CORS headers?"

        Http.BadStatus _ ->
            "Bad Http Status"

        _ ->
            "Other Http error"


zeroPad : String -> String
zeroPad s =
    if String.length s == 1 then
        "0" ++ s

    else
        s


toMonthNumber : Month -> String
toMonthNumber month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


toUtcString : Time.Posix -> String
toUtcString time =
    String.fromInt (toYear utc time)
        ++ "-"
        ++ zeroPad (toMonthNumber (toMonth utc time))
        ++ "-"
        ++ zeroPad (String.fromInt (toDay utc time))
        ++ " "
        ++ zeroPad
            (String.fromInt (toHour utc time))
        ++ ":"
        ++ zeroPad (String.fromInt (toMinute utc time))


type alias Run =
    { start : Int, end : Int }


runDecoder : Decoder Run
runDecoder =
    Decode.succeed Run
        |> required "start" int
        |> required "end" int


lastestRunsResponseDecoder : Decoder LatestRunsResponse
lastestRunsResponseDecoder =
    Decode.succeed LatestRunsResponse
        |> required "latest_runs" (list runDecoder)


getLatestRuns : Cmd Msg
getLatestRuns =
    Http.get
        { url = "http://raspberrypi.lan/api/latest_runs"
        , expect = Http.expectJson GotJson lastestRunsResponseDecoder
        }


type alias Model =
    { latest_runs : List Run
    , page_state : PageState
    , error_message : String
    , time_zone : Time.Zone
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model [] Loading "" Time.utc, getLatestRuns )


type alias LatestRunsResponse =
    { latest_runs : List Run }


type Msg
    = GotJson (Result Http.Error LatestRunsResponse)
    | AdjustTimeZone Time.Zone


type PageState
    = Failure
    | Loading
    | Success


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AdjustTimeZone newZone ->
            ( { model | time_zone = newZone }, Cmd.none )

        GotJson result ->
            case result of
                Ok resp ->
                    ( { model | page_state = Success, latest_runs = resp.latest_runs }, Task.perform AdjustTimeZone Time.here )

                Err e ->
                    ( { model | page_state = Failure, error_message = httpErrorToString e }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    case model.page_state of
        Loading ->
            text "loading..."

        Success ->
            runDiv model

        Failure ->
            text <| "fail! " ++ model.error_message


runDiv model =
    let
        rows =
            [ thead []
                [ tr []
                    [ th []
                        [ text "start"
                        ]
                    , th []
                        [ text "end"
                        ]
                    ]
                ]
            , tbody [] <| List.map (\r -> makeRow r model.time_zone) model.latest_runs
            ]
    in
    table [ class "table table-striped table-hover table-sm" ] rows


makeRow run tz =
    tr []
        [ td [] [ text <| makeDateTime run.start tz ]
        , td [] [ text <| makeDateTime run.end tz ]
        ]


timeToString f tz time =
    zeroPad <| String.fromInt <| f tz (Time.millisToPosix <| time * 1000)


timeToMonthString tz time =
    toMonthNumber (Time.toMonth tz (Time.millisToPosix <| time * 1000))


makeDateTime time tz =
    timeToString Time.toYear tz time
        ++ "-"
        ++ timeToMonthString tz time
        ++ "-"
        ++ timeToString Time.toDay tz time
        ++ " "
        ++ timeToString Time.toHour tz time
        ++ ":"
        ++ timeToString Time.toMinute tz time
