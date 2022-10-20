defmodule Bonfire.UI.Kanban.Routes do
  def declare_routes, do: "kanban"

  defmacro __using__(_) do
    quote do
      # pages anyone can view
      scope "/kanban", Bonfire.UI.Kanban do
        pipe_through(:browser)
      end

      # pages you need an account to view
      scope "/kanban", Bonfire.UI.Kanban do
        pipe_through(:browser)
        pipe_through(:account_required)
      end

      # pages you need a user to view
      scope "/kanban", Bonfire.UI.Kanban do
        pipe_through(:browser)
        pipe_through(:user_required)
        live("/", HomeLive)
        live("/:tab", HomeLive)
        live("/b/:id", BoardLive)
        live("/b/:id/c/:card_id", BoardLive)
        # live "/list/:id", ProcessLive, as: ValueFlows.Process
        # live "/lists", ProcessesLive
        # live "/task/:id", TaskLive, as: ValueFlows.Planning.Intent
        # live "/my-tasks", MyTasksLive
      end
    end
  end
end
