defmodule Bonfire.UI.Kanban.Repo.Migrations.ImportMe  do
  @moduledoc false
  use Ecto.Migration

  import Bonfire.UI.Kanban.Migration
  # accounts & users

  def change, do: migrate_me
end
