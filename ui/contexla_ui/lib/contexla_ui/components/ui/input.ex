defmodule ContexlaUI.Components.UI.Input do
  @moduledoc "Provides form inputs with labels and validation errors."
  use Phoenix.Component
  alias ContexlaUI.Components.UI.Icon

  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)

  attr(:type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file month number password search select tel text textarea time url week hidden)
  )

  attr(:field, Phoenix.HTML.FormField)
  attr(:errors, :list, default: [])
  attr(:checked, :boolean)
  attr(:prompt, :string, default: nil)
  attr(:options, :list)
  attr(:multiple, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:error_class, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(accept autocomplete capture cols disabled form list max maxlength min minlength multiple pattern placeholder readonly required rows size step)
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="mb-3">
      <label for={@id} class="flex cursor-pointer items-center gap-2 text-sm text-text">
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={@class || "size-4 rounded border-border text-primary focus:ring-primary"}
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-3">
      <label for={@id}>
        <span :if={@label} class="mb-1 block text-sm font-medium text-text-muted">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            input_class(@class),
            @errors != [] && (@error_class || "border-red-500 focus:border-red-500")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-3">
      <label for={@id}>
        <span :if={@label} class="mb-1 block text-sm font-medium text-text-muted">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            input_class(@class),
            @errors != [] && (@error_class || "border-red-500 focus:border-red-500")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="mb-3">
      <label for={@id}>
        <span :if={@label} class="mb-1 block text-sm font-medium text-text-muted">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            input_class(@class),
            @errors != [] && (@error_class || "border-red-500 focus:border-red-500")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex items-center gap-1.5 text-sm text-red-600 dark:text-red-400">
      <Icon.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  def translate_error({message, options}) do
    Enum.reduce(options, message, fn {key, value}, translated ->
      String.replace(translated, "%{#{key}}", to_string(value))
    end)
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, error} <- errors, do: translate_error(error)
  end

  defp input_class(nil),
    do:
      "block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none transition-colors placeholder:text-text-muted focus:border-primary"

  defp input_class(class), do: class
end
