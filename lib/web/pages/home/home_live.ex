defmodule Bonfire.Kanban.Web.HomeLive do
  use Bonfire.Web, {:surface_view, [layout: {Bonfire.UI.Social.Web.LayoutView, "full_template.html"}]}

  alias Bonfire.Web.LivePlugs
  alias Bonfire.Me.Users


  def mount(params, session, socket) do
    LivePlugs.live_plug params, session, socket, [
      LivePlugs.LoadCurrentAccount,
      LivePlugs.LoadCurrentUser,
      LivePlugs.StaticChanged,
      LivePlugs.Csrf, LivePlugs.Locale,
      &mounted/3,
    ]
  end

  defp mounted(params, session, socket) do
    {:ok, socket
    |> assign(
      page_title: "All boards",
    )}
  end

end
