defmodule Bonfire.UI.Kanban.HomeLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  use AbsintheClient,
    schema: Bonfire.API.GraphQL.Schema,
    action: [mode: :internal]

  alias Bonfire.UI.Me.LivePlugs
  alias Bonfire.Me.Users

  prop selected_tab, :string, default: "publish"

  declare_extension("Kanban", icon: "twemoji:clipboard")

  def mount(params, session, socket) do
    live_plug(params, session, socket, [
      LivePlugs.LoadCurrentAccount,
      LivePlugs.LoadCurrentUser,
      Bonfire.UI.Common.LivePlugs.StaticChanged,
      Bonfire.UI.Common.LivePlugs.Csrf,
      Bonfire.UI.Common.LivePlugs.Locale,
      &mounted/3
    ])
  end

  defp mounted(params, session, socket) do
    {:ok,
     assign(
       socket,
       page_title: "All boards",
       selected_tab: "discover",
       boards: processes(socket),
       without_sidebar: true
     )}
  end

  @graphql """
  {
    processes {
      id
      name
      note
      has_end
      intended_outputs {
        finished
      }
    }
  }
  """
  def processes(params \\ %{}, socket), do: liveql(socket, :processes, params)

  def do_handle_params(%{"tab" => "publish" = tab} = _params, _url, socket) do
    current_user = current_user_required!(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def do_handle_params(%{"tab" => "discover" = tab} = _params, _url, socket) do
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def do_handle_params(
        %{"tab" => "my-workspaces" = tab} = _params,
        _url,
        socket
      ) do
    current_user = current_user_required!(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def do_handle_params(%{"tab" => tab} = _params, _url, socket) do
    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def do_handle_params(%{} = _params, _url, socket) do
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
       selected_tab: "discover"
     )}
  end

  def handle_params(params, uri, socket) do
    # poor man's hook I guess
    with {_, socket} <-
           Bonfire.UI.Common.LiveHandlers.handle_params(params, uri, socket) do
      undead_params(socket, fn ->
        do_handle_params(params, uri, socket)
      end)
    end
  end

  def handle_event(action, attrs, socket),
    do:
      Bonfire.UI.Common.LiveHandlers.handle_event(
        action,
        attrs,
        socket,
        __MODULE__
      )
end
