defmodule PjeskiWeb.SessionView do
  import Pjeski.FeatureFlags, only: [registration_enabled?: 0, mailing_enabled?: 0]
  use PjeskiWeb, :view
end
