defmodule Bonfire.UI.Kanban.CreateCardLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop board_id, :string
  prop bin_id, :string
end
