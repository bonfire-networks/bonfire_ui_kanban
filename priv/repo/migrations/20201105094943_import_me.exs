defmodule Bonfire.KanbanRepo.Migrations.ImportMe do
  use Ecto.Migration

  import Bonfire.KanbanMigration
  # accounts & users

  def change, do: migrate_me

end
