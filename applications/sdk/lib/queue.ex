defmodule Contexla.Applications.Sdk.Queue do
  @moduledoc "A named Oban queue declared by an Application."

  @enforce_keys [:name, :concurrency]
  defstruct [:name, :concurrency]

  @type t :: %__MODULE__{
          name: atom(),
          concurrency: pos_integer()
        }

  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = queue) do
    if is_atom(queue.name) and is_integer(queue.concurrency) and queue.concurrency > 0,
      do: :ok,
      else: {:error, {:invalid_queue, queue.name}}
  end
end
