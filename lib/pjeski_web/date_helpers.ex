defmodule PjeskiWeb.DateHelpers do
  use Timex
  alias Pjeski.Users.User

  @default_time_zone "Europe/Warsaw"

  def dt(_, nil), do: ""

  def dt(%User{time_zone: time_zone, locale: locale}, datetime) do
    convert_datetime(datetime, time_zone, locale)
  end

  def dt(%Plug.Conn{assigns: %{current_user: %User{time_zone: time_zone}, locale: locale}}, datetime) do
    convert_datetime(datetime, time_zone, locale)
  end

  def dt(%Plug.Conn{assigns: %{locale: locale}}, datetime) do
    convert_datetime(datetime, @default_time_zone, locale)
  end

  defp convert_datetime(datetime, time_zone, locale) do
    format = "{D} {Mfull} {YYYY} {h24}:{m}"

    {:ok, result} = Timex.lformat(Timezone.convert(datetime, time_zone), format, locale)

    result
  end
end
