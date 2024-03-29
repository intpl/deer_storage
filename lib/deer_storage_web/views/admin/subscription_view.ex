defmodule DeerStorageWeb.Admin.SubscriptionView do
  alias DeerStorageWeb.Router.Helpers, as: Routes
  use DeerStorageWeb, :view

  def storage_limit_from_kilobytes(requested_val) do
    case Enum.find(storage_limit_options(), fn {_key, val} -> val == requested_val end) do
      nil -> "#{requested_val} KB"
      {text, _size} -> text
    end
  end

  def storage_limit_options(selected_option \\ nil) do
    default_limits_list = default_limits_list()

    case selected_option do
      nil -> default_limits_list
      _ ->
        case Enum.find(default_limits_list, fn {_text, value} -> value == selected_option end) do
          nil -> ["#{selected_option} KB" | default_limits_list]
          _ -> default_limits_list
        end
    end
  end

  def determine_if_sorted(title, field, sort_by, query) do
    case Regex.scan(~r/(.*)_(.*)$/, sort_by) do
      [[_match, ^field, order]] ->
        case order do
            "asc" -> link("⮝ " <> title, to: "?sort_by=#{field}_desc&query=#{query}")
            "desc" -> link("⮟ " <> title, to: "?sort_by=#{field}_asc&query=#{query}")
        end
      _ -> link(title, to: "?sort_by=#{field}_desc&query=#{query}")
    end
  end

  def subscriptions_sorting_options do
    descending = " (#{gettext("descending")})"
    ascending = " (#{gettext("ascending")})"

    [
      ["", gettext("No sorting")],
      ["name_desc", gettext("Name") <> descending],
      ["name_asc", gettext("Name") <> ascending],
      ["expires_on_desc", gettext("Expires on") <> descending],
      ["expires_on_asc", gettext("Expires on") <> ascending],
      ["files_limit_desc", gettext("Files limit") <> descending],
      ["files_limit_asc", gettext("Files limit") <> ascending],
      ["tables_limit_desc", gettext("Tables limit") <> descending],
      ["tables_limit_asc", gettext("Tables limit") <> ascending],
      ["records_per_table_limit_desc", gettext("Records per table limit") <> descending],
      ["records_per_table_limit_asc", gettext("Records per table limit") <> ascending],
      ["storage_limit_kilobytes_desc", gettext("Storage limit") <> descending],
      ["storage_limit_kilobytes_asc", gettext("Storage limit") <> ascending],
      ["admin_notes_desc", gettext("Admin notes") <> descending],
      ["admin_notes_asc", gettext("Admin notes") <> ascending],
      ["inserted_at_desc", gettext("Inserted at") <> descending],
      ["inserted_at_asc", gettext("Inserted at") <> ascending],
      ["updated_at_desc", gettext("Updated at") <> descending],
      ["updated_at_asc", gettext("Updated at") <> ascending],
      ["users_count_desc", gettext("Users") <> descending],
      ["users_count_asc", gettext("Users") <> ascending]
    ]
  end

  defp default_limits_list do
    [
      {"0 MB", 0},
      {"50 MB", 51_200},
      {"100 MB", 102_400},
      {"200 MB", 204_800},
      {"500 MB", 512_000},
      {"1 GB", 1_024_000},
      {"5 GB", 5_120_000},
      {"10 GB", 10_240_000},
      {"20 GB", 20_480_000},
      {"50 GB", 51_200_000}
    ]
  end
end
