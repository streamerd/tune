defmodule TuneWeb.LoggedInTest do
  use TuneWeb.ConnCase

  alias Tune.Fixtures

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  setup %{conn: conn} do
    session_id = Fixtures.session_id()
    credentials = Fixtures.credentials()

    Tune.Spotify.SessionMock
    |> expect(:setup, 2, fn ^session_id, ^credentials -> :ok end)
    |> expect(:get_profile, 2, fn ^session_id -> Fixtures.profile() end)

    [
      session_id: session_id,
      conn: init_test_session(conn, spotify_id: session_id, spotify_credentials: credentials)
    ]
  end

  test "it displays not playing", %{conn: conn, session_id: session_id} do
    Tune.Spotify.SessionMock
    |> expect(:now_playing, 2, fn ^session_id -> :not_playing end)

    {:ok, explorer_live, disconnected_html} = live(conn, "/")

    assert disconnected_html =~ "Not playing."
    assert render(explorer_live) =~ "Not playing."
  end

  test "it displays a song playing", %{conn: conn, session_id: session_id} do
    track = Fixtures.track()

    Tune.Spotify.SessionMock
    |> expect(:now_playing, 2, fn ^session_id -> {:playing, track} end)

    {:ok, explorer_live, disconnected_html} = live(conn, "/")

    assert disconnected_html =~ track.name
    assert render(explorer_live) =~ track.name
  end

  test "it updates when the song changes", %{conn: conn, session_id: session_id} do
    track = Fixtures.track()

    Tune.Spotify.SessionMock
    |> expect(:now_playing, 2, fn ^session_id -> {:playing, track} end)

    {:ok, explorer_live, _html} = live(conn, "/")

    now_playing = {:playing, %{track | name: "Another song"}}

    send(explorer_live.pid, now_playing)

    render(explorer_live) =~ "Another song"
  end
end