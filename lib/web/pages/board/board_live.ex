defmodule Bonfire.UI.Kanban.BoardLive do
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

  defp mounted(%{"id"=> id} = params, _session, socket) do
    process = process(%{id: id}, socket) |> IO.inspect

    {:ok, socket
    |> assign(
      page_title: "Board",
      bins: [%{name: "Dependencies", cards: process.intended_inputs}, %{name: "To do", cards: process.intended_outputs}],
      board_id: id,
      card_id: params[:card_id],
      board: process
    )}
  end

  @quantity_fields """
  {
    has_numerical_value
    has_unit {
      label
      symbol
    }
  }
  """

  @resource_fields """
  {
    id
    name
    note
    image
    onhand_quantity #{@quantity_fields}
    accounting_quantity #{@quantity_fields}
  }
  """

  @intent_fields """
  {
    id
    name
    note
    due
    finished
    context: in_scope_of
    available_quantity #{@quantity_fields}
    resource_quantity #{@quantity_fields}
    effort_quantity #{@quantity_fields}
    provider {
      id
      name
      display_username
      image
    }
    receiver {
      id
      name
      display_username
      image
    }
    resource_inventoried_as #{@resource_fields}
  }
  """
  def intent_fields, do: @intent_fields

  @graphql """
  query($id: ID, $intent_filter: IntentSearchParams) {
    process(id: $id) {
      id
      name
      note
      has_end
      finished
      working_agents {
        id
        name
        image
      }
      intended_inputs(filter: $intent_filter) #{@intent_fields}
      intended_outputs(filter: $intent_filter) #{@intent_fields}
    }
  }
  """

  def process(params \\ %{}, socket), do: liveql(socket, :process, params)
  def process_filtered(params \\ %{}, socket), do: liveql(socket, :process, params)


  def handle_event("search", %{"key" => "Enter", "value" => search_term} = attrs, %{assigns: %{process: process}} = socket) do
    process = process_filtered(%{id: process.id, intent_filter: %{"searchString" => search_term}}, socket)
    {:noreply, socket |> assign(process: process)}
  end

  def handle_event("search", attrs, socket) do
    {:noreply, socket}
  end


  def handle_event("dropped", %{"draggedId" => dragged_id, "dropzoneId" => drop_zone_id,"draggableIndex" => draggable_index}, socket) do

    # implementation will go here
    IO.inspect(dragged_id: dragged_id)
    IO.inspect(draggable_index: draggable_index)
    {:noreply, socket}

  end

  def handle_event("show", id, socket) do
  {:noreply,
    push_redirect(
      socket,
      to: "/kanban/b/test/c/123"
    )
  }
  end

  def handle_event(action, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_event(action, attrs, socket, __MODULE__)

  def handle_params(%{"card_id" => id}=_params, _uri, socket) do
    IO.inspect(card_id: id)
    {:noreply, assign(socket, :card_id, id)}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, assign(socket, :card_id, nil)}
  end

  def handle_params(%{"filter" => status}, _, %{assigns: %{process: process}} = socket) do
    process = process_filtered(%{id: process.id, intent_filter: %{"status" => status}}, socket)
    {:noreply, socket |> assign(process: process)}
  end
  def handle_params(params, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_params(params, attrs, socket, __MODULE__)


    def handle_info(info, socket), do: Bonfire.Common.LiveHandlers.handle_info(info, socket, __MODULE__)
end
