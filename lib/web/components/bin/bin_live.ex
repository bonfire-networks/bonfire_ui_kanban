defmodule Bonfire.UI.Kanban.BinLive do
  use Bonfire.Web, :stateless_component
  prop bin, :any
  prop drop_zone_id, :string
end
