defmodule DeerStorageWeb.SessionView do
  import DeerStorage.FeatureFlags, only: [registration_enabled?: 0, mailing_enabled?: 0]
  use DeerStorageWeb, :view
end
