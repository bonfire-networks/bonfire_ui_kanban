defmodule Bonfire.UI.Kanban.CardModalLive do
  use Bonfire.Web, :stateless_component

  prop card, :map
  prop board_id, :string
end
