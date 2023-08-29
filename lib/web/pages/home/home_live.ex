defmodule Bonfire.UI.Kanban.HomeLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  use AbsintheClient,
    schema: Bonfire.API.GraphQL.Schema,
    action: [mode: :internal]

  alias Bonfire.Me.Users

  prop selected_tab, :string, default: "publish"

  declare_extension("Kanban", icon: "twemoji:clipboard", emoji: "📋")

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

  def do_handle_params(%{"tab" => "publish" = tab} = _params, _url, socket) do
    current_user = current_user_required!(socket)

    {:noreply,
     assign(socket,
       selected_tab: tab
     )}
  end

  def do_handle_params(%{"tab" => "discover" = tab} = _params, _url, socket) do
    current_user = current_user(socket.assigns)

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
    current_user = current_user(socket.assigns)

    {:noreply,
     assign(socket,
       selected_tab: "discover"
     )}
  end

  def handle_params(params, uri, socket),
    do:
      Bonfire.UI.Common.LiveHandlers.handle_params(
        params,
        uri,
        socket,
        __MODULE__,
        &do_handle_params/3
      )

  def handle_info(info, socket),
    do: Bonfire.UI.Common.LiveHandlers.handle_info(info, socket, __MODULE__)

  def handle_event(
        action,
        attrs,
        socket
      ),
      do:
        Bonfire.UI.Common.LiveHandlers.handle_event(
          action,
          attrs,
          socket,
          __MODULE__
          # &do_handle_event/3
        )
end
