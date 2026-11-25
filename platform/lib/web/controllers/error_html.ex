defmodule Contexla.Platform.Web.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use Contexla.Platform.Web, :html

  embed_templates "error_html/*"

  attr :status, :string, required: true
  attr :title, :string, required: true
  attr :message, :string, required: true
  attr :icon, :string, required: true

  def public_error(assigns) do
    ~H"""
    <main class="flex min-h-dvh items-center justify-center bg-bg px-5 py-12 text-text">
      <div class="w-full max-w-lg text-center">
        <Layouts.brand_mark class="mx-auto size-20" />
        <section class="mt-12 overflow-hidden rounded-3xl border border-border bg-surface shadow-xl">
          <div class="h-1.5 bg-gradient-to-r from-primary via-violet-500 to-accent"></div>
          <div class="px-8 py-12">
            <p class="font-semibold tracking-[0.2em] text-primary">{@status}</p>
            <span class="mx-auto mt-5 grid size-14 place-items-center rounded-2xl bg-primary-subtle text-primary">
              <.icon name={@icon} class="size-7" />
            </span>
            <h1 class="mt-6 text-2xl font-semibold">{@title}</h1>
            <p class="mx-auto mt-3 max-w-sm text-sm leading-6 text-text-muted">{@message}</p>
            <a href="/" class="btn btn-primary mt-7">Return home <span aria-hidden="true">→</span></a>
          </div>
        </section>
        <p class="mt-6 text-xs text-text-muted">
          Reliable content operations, backed by traceable evidence.
        </p>
      </div>
    </main>
    """
  end
end
