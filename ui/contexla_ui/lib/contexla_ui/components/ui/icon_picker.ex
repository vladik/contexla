defmodule ContexlaUI.Components.UI.IconPicker do
  @moduledoc "Reusable compact picker for the shared platform icon vocabulary."
  use Phoenix.Component

  import ContexlaUI.Components.UI.Icon

  @icons ~w(
    hero-archive-box hero-beaker hero-bolt hero-book-open hero-building-library
    hero-chart-bar-square hero-check-badge hero-circle-stack hero-clipboard-document-check
    hero-cloud hero-code-bracket hero-cog-6-tooth hero-cube hero-document-chart-bar
    hero-document-magnifying-glass hero-finger-print hero-globe-alt hero-link
    hero-magnifying-glass hero-map hero-photo hero-puzzle-piece hero-rocket-launch
    hero-server-stack hero-shield-check hero-squares-2x2 hero-tag hero-wrench-screwdriver
  )

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:default_icon, :string, required: true)
  attr(:label, :string, default: "Instance icon")
  attr(:icons, :list, default: @icons)

  def icon_picker(assigns) do
    assigns = assign(assigns, :display_icon, assigns.value || assigns.default_icon)

    ~H"""
    <div>
      <span class="mb-1 block text-sm font-medium text-text-muted">{@label}</span>
      <details id={@id} data-icon-picker class="relative w-fit">
        <summary
          class="grid size-11 cursor-pointer list-none place-items-center rounded-xl border border-border bg-surface text-primary transition-colors hover:bg-surface-raised [&::-webkit-details-marker]:hidden"
          aria-label="Choose Instance icon"
        >
          <.icon name={@display_icon} class="size-5" />
        </summary>

        <div class="absolute start-0 top-full z-50 mt-2 w-72 rounded-xl border border-border bg-surface p-2 shadow-xl">
          <label class={[
            "mb-2 flex cursor-pointer items-center gap-2 rounded-lg border px-2.5 py-2 text-xs transition-colors",
            if(is_nil(@value) or @value == "",
              do: "border-primary bg-primary-subtle text-primary",
              else: "border-border text-text-muted hover:bg-surface-raised hover:text-text"
            )
          ]}>
            <input
              type="radio"
              name={@name}
              value=""
              checked={is_nil(@value) or @value == ""}
              class="sr-only"
            />
            <.icon name={@default_icon} class="size-4" /> Application default
          </label>

          <div class="grid max-h-48 grid-cols-7 gap-1 overflow-y-auto">
            <label
              :for={icon <- @icons}
              class={[
                "grid aspect-square cursor-pointer place-items-center rounded-lg transition-colors",
                if(icon == @value,
                  do: "bg-primary-subtle text-primary",
                  else: "text-text-muted hover:bg-surface-raised hover:text-text"
                )
              ]}
              title={humanize(icon)}
            >
              <input
                type="radio"
                name={@name}
                value={icon}
                checked={icon == @value}
                class="sr-only"
              />
              <.icon name={icon} class="size-5" />
              <span class="sr-only">{humanize(icon)}</span>
            </label>
          </div>
        </div>
      </details>
    </div>
    """
  end

  def icons, do: @icons

  defp humanize("hero-" <> icon),
    do: icon |> String.replace("-", " ") |> String.capitalize()
end
