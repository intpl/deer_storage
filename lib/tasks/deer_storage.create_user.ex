defmodule Mix.Tasks.DeerStorage.CreateUser do
  use Mix.Task

  alias DeerStorage.Users

  @shortdoc "Creates user, eg. mix deer_storage.create_user admin user@example.org"

  def run([role, email]) do
    Mix.Task.run "app.start"
    Mix.shell.info "Generating random password..."
    password = :crypto.strong_rand_bytes(64) |> Base.encode64
    Mix.shell.info "Password for user #{email} will be: #{password}"
    Mix.shell.info "Creating user..."
    {:ok, _} = Users.admin_create_user(%{email: email, name: "Change me", password: password, password_confirmation: password, role: role})
    Mix.shell.info "Created user #{email}..."
  end
end
