defmodule Bonfire.UI.Kanban.BoardLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  use AbsintheClient,
    schema: Bonfire.API.GraphQL.Schema,
    action: [mode: :internal]

  alias Bonfire.UI.ValueFlows.IntentCreateActivityLive
  alias Bonfire.UI.ValueFlows.CreateMilestoneLive

  alias Bonfire.UI.ValueFlows.FiltersLive

  alias Bonfire.Me.Users
  alias Bonfire.UI.Me.CreateUserLive

  # @default_filters %{intent_filter: %{"classified_as"=> [Bonfire.UI.Kanban.remote_tag_id]}} # TODO: activate this filter to filter any non-Tasks
  @default_filters %{}

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(%{"id" => id} = params, _session, socket) do
    current_user = current_user(socket.assigns)

    task_tag_id =
      ValueFlows.Util.maybe_classification_id(
        current_user,
        Bonfire.UI.Kanban.remote_tag_id()
      )

    process = process(%{id: id}, socket) |> IO.inspect()

    # |> IO.inspect
    all_cards =
      Map.new(process.intended_inputs ++ process.intended_outputs, fn x ->
        {x.id, x}
      end)

    # TODO: generate bins from taxonomy

    todo = Enum.reject(process.intended_outputs, & &1.finished)

    unassigned = Enum.reject(todo, & &1.provider)
    todo = Enum.reject(todo, &(!&1.provider))

    someday = Enum.reject(todo, & &1.due)
    todo = Enum.reject(todo, &(!&1.due))

    finished = Enum.reject(process.intended_outputs, &(!&1.finished))

    bins = [
      %{
        id: upstream_tag_id(current_user, "Dependencies"),
        name: "Dependencies",
        cards: process.intended_inputs
      },
      %{
        id: upstream_tag_id(current_user, "Up_for_grabs"),
        name: "Up for grabs",
        cards: unassigned
      },
      %{
        id: upstream_tag_id(current_user, "Someday"),
        name: "Someday",
        cards: someday
      },
      %{id: upstream_tag_id(current_user, "To_do"), name: "To do", cards: todo},
      %{
        id: upstream_tag_id(current_user, "Urgent"),
        name: "Urgent",
        cards: nil
      },
      %{
        id: upstream_tag_id(current_user, "Done"),
        name: "Done",
        cards: finished
      }
    ]

    suggested_bins = Enum.reject(bins, &(is_list(&1.cards) and length(&1.cards) > 0))

    bins = Enum.reject(bins, &(!&1.cards || length(&1.cards) == 0))

    {:ok,
     assign(
       socket,
       page_title: "Board",
       all_cards: all_cards,
       bins: bins,
       suggested_bins: suggested_bins,
       board_id: id,
       card_id: params[:card_id],
       board: Map.drop(process, [:intended_inputs, :intended_outputs]),
       task_tag_id: task_tag_id,
       without_sidebar: true,
       showing_within: :board
     )}
  end

  def upstream_tag_id(current_user, tag_slug) do
    ValueFlows.Util.maybe_classification_id(
      current_user,
      "#{Bonfire.UI.Kanban.remote_tag_prefix()}#{tag_slug}"
    )
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
    tags
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

  def process(params \\ @default_filters, socket),
    do: liveql(socket, :process, Map.merge(@default_filters, params))

  def handle_event(
        "search",
        %{"key" => "Enter", "value" => search_term} = attrs,
        %{assigns: %{board_id: board_id}} = socket
      ) do
    process =
      process(
        %{id: board_id, intent_filter: %{"searchString" => search_term}},
        socket
      )

    {:noreply, assign(socket, process: process)}
  end

  def handle_event("search", attrs, socket) do
    {:noreply, socket}
  end

  def handle_event("create_bin", %{"input_tag" => input_tag} = attrs, socket) do
    debug(input_tag)

    with {:ok, [%{"text" => label, "value" => id}]} <- Jason.decode(input_tag) do
      debug(id, "create_bin ID")

      if is_uid?(id) do
        {:noreply,
         assign(socket,
           bins: e(socket.assigns, :bins, []) ++ [%{id: id, name: label, cards: []}]
         )}
      else
        # TODO: create new?
        {:noreply, socket}
      end
    else
      e ->
        # TODO: not JSON?
        error(e)
        {:noreply, socket}
    end
  end

  def handle_event(
        "dropped",
        %{
          "dragged_id" => "bin:" <> dragged_id,
          "dropped_index" => dropped_index
        } = params,
        socket
      ) do
    debug(dragged_id: dragged_id)
    debug(dropped_index: dropped_index)

    # implementation for bin ordering
    Bonfire.Data.Assort.Ranked.changeset(%{
      item_id: dragged_id,
      scope_id: e(socket.assigns, :board_id, nil),
      rank_set: dropped_index
    })
    |> repo().insert_or_ignore()

    {:noreply, socket}
  end

  def handle_event(
        "dropped",
        %{
          "dragged_id" => dragged_id,
          "dragged_from_id" => previous_bin,
          "dropped_to_id" => new_bin,
          "dropped_index" => dropped_index
        } = params,
        socket
      ) do
    debug(dragged_id: dragged_id)
    debug(previous_bin: previous_bin)
    debug(new_bin: new_bin)
    debug(dropped_index: dropped_index)

    # implementation for bin membership & card ordering:

    # add the bin as a tag (and remove the previous one)
    if previous_bin != new_bin do
      existing_tags = e(socket.assigns, :all_cards, dragged_id, :tags, [])

      new_tags =
        [e(socket.assigns, :task_tag_id, nil), new_bin] ++
          Enum.reject(existing_tags, &(&1.id == previous_bin))

      # debug(new_tags, "new_tags")
      ValueFlows.Util.try_tag_thing(current_user_required!(socket), dragged_id, new_tags)
    end

    # save the order
    Bonfire.Data.Assort.Ranked.changeset(%{
      item_id: dragged_id,
      scope_id: new_bin,
      rank_set: dropped_index
    })
    |> repo().insert_or_ignore()

    {:noreply, socket}
  end

  # def handle_event("show", id, socket) do
  # {:noreply,
  #   redirect_to(
  #     socket,
  #     "/kanban/b/test/c/123"
  #   )
  # }
  # end

  def handle_params(%{"card_id" => id} = _params, _uri, socket) do
    debug(card_id: id)

    {:noreply,
     assign(socket,
       card_id: id,
       selected_card: e(socket.assigns, :all_cards, id, nil)
     )}
  end

  def handle_params(_, _uri, socket) do
    {:noreply, assign(socket, card_id: nil, selected_card: nil)}
  end

  def handle_params(
        %{"filter" => status},
        _,
        %{assigns: %{process: process}} = socket
      ) do
    process = process(%{id: process.id, intent_filter: %{"status" => status}}, socket)

    {:noreply, assign(socket, process: process)}
  end

  def handle_params(params, attrs, socket), do: {:noreply, socket}
end
