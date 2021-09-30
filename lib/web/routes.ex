defmodule Bonfire.Kanban.Web.Routes do
  defmacro __using__(_) do

    quote do

      # pages anyone can view
      scope "/kanban", Bonfire.Kanban do
        pipe_through :browser
        live "/", Web.HomeLive
        # live "/list/:id", ProcessLive, as: ValueFlows.Process
        # live "/lists", ProcessesLive
        # live "/task/:id", TaskLive, as: ValueFlows.Planning.Intent
        # live "/my-tasks", MyTasksLive
      end

    end
  end
end
