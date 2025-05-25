defmodule Bonfire.UI.Kanban.HomeLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  use AbsintheClient,
    schema: Bonfire.API.GraphQL.Schema,
    action: [mode: :internal]

  alias Bonfire.Me.Users

  prop selected_tab, :any, default: "publish"

  declare_extension("Kanban",
    icon: "ph:kanban-fill",
    emoji: "📋",
    description:
      l(
        "Collaborative tools for decentralized project coordination, such as task lists and Kanban."
      )
  )

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(params, session, socket) do
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

  def handle_params(%{"tab" => "publish" = tab} = _params, _url, socket) do
    current_user = current_user_required!(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def handle_params(%{"tab" => "discover" = tab} = _params, _url, socket) do
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def handle_params(
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

  def handle_params(%{"tab" => tab} = _params, _url, socket) do
    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def handle_params(%{} = _params, _url, socket) do
    current_user = current_user(socket)

    {:noreply,
     assign(socket,
       selected_tab: "discover"
     )}
  end
end
