defmodule Bonfire.UI.Kanban.CardHeroLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop card, :map
  prop board_id, :string
end
