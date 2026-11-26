defmodule Contexla.Ui.ContexlaUi.Components.UI.TagInput do
  use Phoenix.Component
  import Contexla.Ui.ContexlaUi.Components.UI.Icon

  attr :id, :string, required: true
  attr :tags, :list, default: []
  attr :label, :string, default: nil
  attr :placeholder, :string, default: "Type a tag and press Enter"
  attr :target, :any, default: nil

  @doc """
  A tag chip input. The parent LiveView must handle `add_tag` and `remove_tag` events.

  `add_tag` fires on form submit (Enter key) with params `%{"tag" => text}`.
  `remove_tag` fires on button click with params `%{"tag" => text}`.

  The input clears on Enter because the form is re-keyed by tag count — LiveView
  destroys and recreates the form DOM when the tag count changes.
  """
  def tag_input(assigns) do
    ~H"""
    <div id={@id}>
      <span :if={@label} class="mb-1.5 block text-sm font-medium text-text-muted">{@label}</span>
      <div class="flex min-h-[2.5rem] flex-wrap items-center gap-1.5 rounded-lg border border-border bg-surface px-2.5 py-1.5 transition-colors focus-within:border-primary">
        <span
          :for={tag <- @tags}
          class="inline-flex items-center gap-0.5 rounded-md bg-surface-raised px-2 py-0.5 text-sm text-text"
        >
          {tag}
          <button
            type="button"
            phx-click="remove_tag"
            phx-value-tag={tag}
            phx-target={@target}
            class="ml-0.5 text-text-muted hover:text-text focus:outline-none"
            aria-label={"Remove #{tag}"}
          >
            <.icon name="hero-x-mark" class="size-3" />
          </button>
        </span>
        <%!-- Re-keyed by tag count so LiveView recreates the input after each add, clearing it. --%>
        <form
          id={"#{@id}-input-#{length(@tags)}"}
          phx-submit="add_tag"
          phx-target={@target}
          class="min-w-[8rem] flex-1"
        >
          <input
            type="text"
            name="tag"
            placeholder={if @tags == [], do: @placeholder, else: ""}
            autocomplete="off"
            class="w-full bg-transparent text-sm text-text outline-none placeholder:text-text-muted"
          />
        </form>
      </div>
    </div>
    """
  end
end
