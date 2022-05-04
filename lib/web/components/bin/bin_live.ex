defmodule Bonfire.UI.Kanban.BinLive do
  use Bonfire.UI.Common.Web, :stateless_component
  prop bin, :any
  prop drop_zone_id, :string
  prop board_id, :string
end
