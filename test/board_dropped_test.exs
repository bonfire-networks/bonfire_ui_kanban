defmodule Bonfire.UI.Kanban.BoardDroppedTest do
  @moduledoc """
  Dropping a card on a board saves its rank and, when it moves to another bin, re-tags it. Only someone signed in may do either, and a person may only re-tag objects they are allowed to change. The same event is reachable by a plain request to the `/LiveHandler` route, which carries no session at all.
  """

  use Bonfire.UI.Kanban.ConnCase, async: false

  import Ecto.Query
  import ValueFlows.Simulate, only: [fake_process!: 2, fake_intent!: 2]

  alias Bonfire.Data.Assort.Ranked
  alias Bonfire.Tag.Tagged

  setup do
    account = fake_account!()
    owner = fake_user!(account)
    board = fake_process!(owner, %{finished: false, is_public: true})
    card = fake_intent!(owner, %{})

    {:ok, account: account, owner: owner, board: board, card: card}
  end

  defp ranks(id),
    do: Bonfire.Common.Config.repo().all(from(r in Ranked, where: r.item_id == ^id, select: r.id))

  defp tag_ids(id),
    do: Bonfire.Common.Config.repo().all(from(t in Tagged, where: t.id == ^id, select: t.tag_id))

  defp drop_params(card, bin),
    do: %{
      "dragged_id" => card.id,
      "dragged_from_id" => bin,
      "dropped_to_id" => bin,
      "dropped_index" => "1"
    }

  test "a signed-in user's drop on a board saves the card's rank (control)", %{
    account: account,
    owner: owner,
    board: board,
    card: card
  } do
    {:ok, view, _html} = live(conn(user: owner, account: account), "/kanban/b/#{board.id}")

    render_hook(view, "dropped", drop_params(card, board.id))

    assert [_] = ranks(card.id)
  end

  test "a visitor without a session cannot rank a card", %{board: board, card: card} do
    get(
      build_conn(),
      "/LiveHandler/Bonfire.UI.Kanban.BoardLive/dropped?" <>
        URI.encode_query(drop_params(card, board.id))
    )

    assert ranks(card.id) == []
  end

  test "a visitor without a session cannot rank a bin", %{card: card} do
    get(
      build_conn(),
      "/LiveHandler/Bonfire.UI.Kanban.BoardLive/dropped?" <>
        URI.encode_query(%{"dragged_id" => "bin:#{card.id}", "dropped_index" => "1"})
    )

    assert ranks(card.id) == []
  end

  test "a signed-in user cannot re-tag an object that belongs to someone else", %{
    account: account,
    card: card
  } do
    other = fake_user!(account)
    other_board = fake_process!(other, %{finished: false, is_public: true})
    {:ok, bin} = Bonfire.Tag.get_or_create_hashtag("kanbanbin")

    # control: the same drop on an object of their own does re-tag it
    own_card = fake_intent!(other, %{})
    {:ok, view, _html} = live(conn(user: other, account: account), "/kanban/b/#{other_board.id}")

    render_hook(view, "dropped", %{
      "dragged_id" => own_card.id,
      "dragged_from_id" => "none",
      "dropped_to_id" => bin.id,
      "dropped_index" => "1"
    })

    assert bin.id in tag_ids(own_card.id)

    before_tags = tag_ids(card.id)

    render_hook(view, "dropped", %{
      "dragged_id" => card.id,
      "dragged_from_id" => "none",
      "dropped_to_id" => bin.id,
      "dropped_index" => "1"
    })

    assert tag_ids(card.id) == before_tags
  end
end
