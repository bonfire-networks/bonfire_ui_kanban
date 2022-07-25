defmodule Bonfire.UI.Kanban.Integration do

  def repo, do: Bonfire.Common.Config.get!(:repo_module)

  def mailer, do: Bonfire.Common.Config.get!(:mailer_module)

  def remote_tag_prefix, do: nil # FIXME
  # def remote_tag_prefix, do: "https://bonjour.bonfire.cafe/pub/actors/" # TODO: put in config
  def remote_tag_id, do: "#{remote_tag_prefix}Task"

end
