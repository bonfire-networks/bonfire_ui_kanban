defmodule Bonfire.KanbanListsNavigationLive do
  use Bonfire.Web, :stateless_component

  prop process_url, :string, default: "/list/"

end
