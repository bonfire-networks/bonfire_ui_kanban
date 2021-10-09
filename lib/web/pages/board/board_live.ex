defmodule Bonfire.UI.Kanban.BoardLive do
  use Bonfire.Web, {:surface_view, [layout: {Bonfire.UI.Social.Web.LayoutView, "full_template.html"}]}

  use AbsintheClient, schema: Bonfire.GraphQL.Schema, action: [mode: :internal]

  alias Bonfire.UI.ValueFlows.{IntentCreateActivityLive, CreateMilestoneLive, ProposalFeedLive, FiltersLive}
  alias Bonfire.Web.LivePlugs
  alias Bonfire.Me.Users
  alias Bonfire.Me.Web.{CreateUserLive, LoggedDashboardLive}

  # @default_filters %{intent_filter: %{"classified_as"=> [Bonfire.UI.Kanban.Integration.remote_tag_id]}} # TODO: activate this filter to filter any non-Tasks
  @default_filters %{}


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

    current_user = current_user(socket)

    process = process(%{id: id}, socket) |> IO.inspect

    all_cards = Map.new(process.intended_inputs ++ process.intended_outputs, fn x -> {x.id, x} end) #|> IO.inspect

    # TODO: generate bins from taxonomy

    todo = process.intended_outputs |> Enum.reject(&(&1.finished))

    unassigned = todo |> Enum.reject(&(!&1.provider))
    todo = todo |> Enum.reject(&(&1.provider))

    someday = todo |> Enum.reject(&(!&1.due))
    todo = todo |> Enum.reject(&(&1.due))

    finished = process.intended_outputs |> Enum.reject(&(!&1.finished))

    bins = [%{id: upstream_tag_id(current_user, "Dependencies"), name: "Dependencies", cards: process.intended_inputs}, %{id: upstream_tag_id(current_user, "Up_for_grabs"), name: "Up for grabs", cards: unassigned}, %{id: upstream_tag_id(current_user, "Someday"), name: "Someday", cards: someday}, %{id: upstream_tag_id(current_user, "To_do"), name: "To do", cards: todo}, %{id: upstream_tag_id(current_user, "Done"), name: "Done", cards: finished}]

    {:ok, socket
    |> assign(
      page_title: "Board",
      all_cards: all_cards,
      bins: bins,
      board_id: id,
      card_id: params[:card_id],
      board: process |> Map.drop([:intended_inputs, :intended_outputs])
    )}
  end

  def upstream_tag_id(current_user, tag_slug) do
    ValueFlows.Util.maybe_classification_id(current_user, Bonfire.UI.Kanban.Integration.remote_tag_prefix<>tag_slug)
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

  def process(params \\ @default_filters, socket), do: liveql(socket, :process, Map.merge(@default_filters, params))


  def handle_event("search", %{"key" => "Enter", "value" => search_term} = attrs, %{assigns: %{process: process}} = socket) do
    process = process(%{id: process.id, intent_filter: %{"searchString" => search_term}}, socket)
    {:noreply, socket |> assign(process: process)}
  end

  def handle_event("search", attrs, socket) do
    {:noreply, socket}
  end

  def handle_event("dropped", %{"draggedId" => "bin:"<>dragged_id, "dropzoneId" => drop_zone_id,"draggableIndex" => draggable_index} = params, socket) do

    # implementation for bin ordering will go here
    IO.inspect(dragged_id: dragged_id)
    IO.inspect(draggable_index: draggable_index)

    {:noreply, socket}

  end

  def handle_event("dropped", %{"draggedId" => dragged_id, "dropzoneId" => drop_zone_id,"draggableIndex" => draggable_index} = params, socket) do

    # implementation for card ordering will go here
    IO.inspect(dragged_id: dragged_id)
    IO.inspect(drop_zone_id: drop_zone_id)
    IO.inspect(draggable_index: draggable_index)

    # Bonfire.Data.Assort.Ranked.changeset(%{item_id: dragged_id, scope_id: drop_zone_id, rank_set: draggable_index}) |> Bonfire.Repo.upsert

    {:noreply, socket}

  end

  # def handle_event("show", id, socket) do
  # {:noreply,
  #   push_redirect(
  #     socket,
  #     to: "/kanban/b/test/c/123"
  #   )
  # }
  # end

  def handle_event(action, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_event(action, attrs, socket, __MODULE__)

  def handle_params(%{"card_id" => id}=_params, _uri, socket) do
    IO.inspect(card_id: id)
    {:noreply, assign(socket,
      card_id: id,
      selected_card: e(socket.assigns, :all_cards, id, nil)
    )}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, assign(socket, card_id: nil, selected_card: nil)}
  end

  def handle_params(%{"filter" => status}, _, %{assigns: %{process: process}} = socket) do
    process = process(%{id: process.id, intent_filter: %{"status" => status}}, socket)
    {:noreply, socket |> assign(process: process)}
  end
  def handle_params(params, attrs, socket), do: Bonfire.Common.LiveHandlers.handle_params(params, attrs, socket, __MODULE__)


    def handle_info(info, socket), do: Bonfire.Common.LiveHandlers.handle_info(info, socket, __MODULE__)
end
