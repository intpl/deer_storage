# run this if you don't have elixir installed: docker run -i --rm -v $(pwd)/initial-setup-env.exs:/s.exs elixir:1.11-alpine elixir /s.exs

defmodule EnvGenerator do
  def show_separator(struct) do
    IO.puts "########################################"

    struct
  end

  def consume_env_key(%{key: key, data: %{value: fun}}) when is_function(fun), do: "#{key}=#{fun.()}"
  def consume_env_key(%{key: key, data: %{value: value}}), do: "#{key}=#{value}"

  def get_and_maybe_put_value_from_user(%{key: key, data: data} = env_struct) do
    IO.puts("# #{data.description}")

    value = case (IO.gets("#{key} [default: #{data.value}]: ") |> String.trim) do
              "" -> data.value
              user_value -> user_value
            end

    Map.put(env_struct, :data, Map.put(data, :value, value))
  end
end

generate_secret = fn (binary_length) ->
  fn -> :crypto.strong_rand_bytes(64) |> Base.encode64 |> binary_part(0, binary_length) end
end

env_structs = [
  # hidden values
  %{key: "APP_HTTP_PORT", data: %{value: "80", hidden: true}},
  %{key: "APP_HTTPS_PORT", data: %{value: "443", hidden: true}},
  %{key: "SECRET_KEY_BASE_CONFIG", data: %{value: generate_secret.(64), hidden: true}},
  %{key: "SECRET_KEY_BASE_RELEASE", data: %{value: generate_secret.(64), hidden: true}},
  %{key: "SECRET_SIGNING_SALT", data: %{value: generate_secret.(32), hidden: true}},
  %{key: "PGUSER", data: %{value: "deer", hidden: true}},
  %{key: "PGPASSWORD", data: %{value: generate_secret.(Enum.random(30..60)), hidden: true}},
  %{key: "PGHOST", data: %{value: "db", hidden: true}},
  %{key: "PGPORT", data: %{value: "5432", hidden: true}},
  %{key: "PGDATABASE", data: %{value: "deer_storage", hidden: true}},
  %{key: "POW_MAILGUN_BASE_URI", data: %{value: "", hidden: true}},
  %{key: "POW_MAILGUN_DOMAIN", data: %{value: "", hidden: true}},
  %{key: "POW_MAILGUN_API_KEY", data: %{value: "", hidden: true}},
  %{key: "LETSENCRYPT_STAGING", data: %{value: "0", hidden: true}},
  %{key: "FEATURE_REGISTRATION", data: %{value: "1", hidden: true}},

  # user-visible values
  %{key: "APP_HOST", data: %{
       value: "localhost",
       description: "This is used both for urls generation in the app and for (optional) Let's Encrypt certificate requests. Application is unusable without setting it up correctly. You can write your domain here (e.g. 'demo.example.org') or just keep localhost for testing locally. Don't use quotes."
    }},
  %{key: "LETSENCRYPT_ENABLED", data: %{
       value: "0",
       description: "Set it to 1 if you want to have signed Let's Encrypt certificate for your domain (does not work for localhost obviously). If left 0, self-signed certificate will be used."
    }
  },
  %{key: "LETSENCRYPT_EMAIL", data: %{
       value: "",
       description: "It's strongly recommended to set it to valid e-mail address if you use Let's Encrypt, but keeping it empty is possible and everything works."
    }
  },
  %{key: "FEATURE_AUTOCONFIRM_AND_PROMOTE_FIRST_USER_TO_ADMIN", data: %{
       value: "1",
       description: "First user that registers to this DeerStorage instance will be autoconfirmed and promoted to administrator automatically. DON'T CHANGE THIS or else you will have to promote yourself to admin using PostgreSQL console."
    }
  },
  %{key: "NEW_SUBSCRIPTION_DAYS_TO_EXPIRE", data: %{
       value: "90",
       description: "Default lifespan for new databases in days. After expiration database will not be accessible unless changed in admin panel."
    }
  },
  %{key: "NEW_SUBSCRIPTION_RECORDS_PER_TABLE_LIMIT", data: %{
       value: "200000",
       description: "Every new database will limit users to create more than X records per each table. Set lower limit if you don't trust your users. This can be changed for each database in the admin panel."
    }
  },
  %{key: "NEW_SUBSCRIPTION_COLUMNS_PER_TABLE_LIMIT", data: %{
       value: "20",
       description: "Every new database table will limit users to create tables with no more columns than value here represents. This can be changed per database."
    }
  },
  %{key: "NEW_SUBSCRIPTION_TABLES_LIMIT", data: %{
       value: "10",
       description: "Every new database will limit tables a user can create for it. This can be changed per database in the admin panal."
    }
  },
  %{key: "NEW_SUBSCRIPTION_FILES_COUNT_LIMIT", data: %{
       value: "2000",
       description: "Limit files for each new database. This can be changed in admin panel per database."
    }
  },
  %{key: "NEW_SUBSCRIPTION_STORAGE_LIMIT_IN_KILOBYTES", data: %{
       value: "1024000",
       description: "Limit storage space for each new database. Value is represented in kilobytes. Can be changed in admin panel per database. Default value is 1GB."
    }
  }

]

Enum.map(env_structs, fn
  %{data: %{hidden: true}} = env_struct -> EnvGenerator.consume_env_key(env_struct)
  env_struct ->
    env_struct
    |> EnvGenerator.get_and_maybe_put_value_from_user
    |> EnvGenerator.consume_env_key
end)
|> EnvGenerator.show_separator
|> Enum.sort
|> Enum.join("\n")
|> IO.puts
