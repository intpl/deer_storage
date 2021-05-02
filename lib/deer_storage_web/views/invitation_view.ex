defmodule DeerStorageWeb.InvitationView do
  import DeerStorage.FeatureFlags, only: [mailing_disabled?: 0]
  use DeerStorageWeb, :view
end
