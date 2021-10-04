defmodule Bonfire.Kanban.Web.BoardLive do
  use Bonfire.Web, {:surface_view, [layout: {Bonfire.UI.Social.Web.LayoutView, "full_template.html"}]}

  use AbsintheClient, schema: Bonfire.GraphQL.Schema, action: [mode: :internal]

  alias Bonfire.UI.ValueFlows.{IntentCreateActivityLive, CreateMilestoneLive, ProposalFeedLive, FiltersLive}
  alias Bonfire.Web.LivePlugs
  alias Bonfire.Me.Users
  alias Bonfire.Me.Web.{CreateUserLive, LoggedDashboardLive}


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
    IO.inspect(params)
    {:ok, socket
    |> assign(
      page_title: "Board",
      board_id: params[:id],
      card_id: params[:card_id],
    )}
  end




  def handle_params(%{"card_id" => id}=_params, _uri, socket) do
    IO.inspect(id)
    {:noreply, assign(socket, :card_id, id)}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, assign(socket, :card_id, nil)}
  end


  def handle_event("show", id, socket) do
    {:noreply, 
      push_redirect(
        socket, 
        to: "/kanban/test/c/123" 
      )
    }
    end

 
    # defdelegate handle_params(params, attrs, socket), to: Bonfire.Common.LiveHandlers

    def handle_event(action, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_event(action, attrs, socket, __MODULE__)
    def handle_info(info, socket), do: Bonfire.Common.LiveHandlers.handle_info(info, socket, __MODULE__)
end
