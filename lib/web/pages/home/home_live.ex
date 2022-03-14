defmodule Bonfire.UI.Kanban.HomeLive do
  use Bonfire.Web, {:surface_view, [layout: {Bonfire.UI.Social.Web.LayoutView, "without_sidebar.html"}]}
  use AbsintheClient, schema: Bonfire.API.GraphQL.Schema, action: [mode: :internal]

  alias Bonfire.Web.LivePlugs
  alias Bonfire.Me.Users
  prop selected_tab, :string, default: "publish"


  def mount(params, session, socket) do
    LivePlugs.live_plug params, session, socket, [
      LivePlugs.LoadCurrentAccount,
      LivePlugs.LoadCurrentUser,
      LivePlugs.StaticChanged,
      LivePlugs.Csrf, LivePlugs.Locale,
      &mounted/3,
    ]
  end

  defp mounted(params, session, socket) do
    {:ok, socket
    |> assign(
      page_title: "All boards",
      selected_tab: "discover",
      boards: processes(socket) |> IO.inspect
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
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab,
     )}
  end

  def do_handle_params(%{"tab" => "discover" = tab} = _params, _url, socket) do
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
        selected_tab: tab,
     )}
  end

  def do_handle_params(%{"tab" => "my-workspaces" = tab} = _params, _url, socket) do
    current_user = current_user(socket)


    {:noreply,
     assign(socket,
       selected_tab: tab,
     )}
  end


  def do_handle_params(%{"tab" => tab} = _params, _url, socket) do

    {:noreply,
     assign(socket,
       selected_tab: tab,
     )}
  end

  def do_handle_params(%{} = _params, _url, socket) do

    current_user = current_user(socket)

    {:noreply,
     assign(socket,
     selected_tab: "discover",
     )}
  end

  def handle_params(params, uri, socket) do
    undead_params(socket, fn ->
      do_handle_params(params, uri, socket)
    end)
  end

  def handle_event(action, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_event(action, attrs, socket, __MODULE__)

end
