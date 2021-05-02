defmodule PjeskiWeb.InvitationView do
  import Pjeski.FeatureFlags, only: [mailing_disabled?: 0]
  use PjeskiWeb, :view
end
