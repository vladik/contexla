defmodule Contexla.Platform.Connections.EncryptedMap do
  @moduledoc "Ecto type that encrypts a map to a base64 string using AES-256-GCM."

  use Ecto.Type

  @aad "contexla_connections_v1"

  def type, do: :text

  def cast(nil), do: {:ok, nil}
  def cast(map) when is_map(map), do: {:ok, map}
  def cast(_), do: :error

  def load(nil), do: {:ok, nil}

  def load(binary) when is_binary(binary) do
    with {:ok, payload} <- Base.decode64(binary),
         <<iv::binary-12, tag::binary-16, ciphertext::binary>> <- payload,
         plaintext when is_binary(plaintext) <-
           :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, ciphertext, @aad, tag, false),
         {:ok, map} <- Jason.decode(plaintext) do
      {:ok, map}
    else
      _ -> :error
    end
  end

  def dump(nil), do: {:ok, nil}

  def dump(map) when is_map(map) do
    iv = :crypto.strong_rand_bytes(12)
    plaintext = Jason.encode!(map)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, plaintext, @aad, true)
    {:ok, Base.encode64(iv <> tag <> ciphertext)}
  end

  def dump(_), do: :error

  defp key do
    :contexla
    |> Application.fetch_env!(:credential_encryption_key)
    |> Base.decode64!()
  end
end
