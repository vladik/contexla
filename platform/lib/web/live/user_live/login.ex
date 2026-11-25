defmodule Contexla.Platform.Web.UserLive.Login do
  use Contexla.Platform.Web, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main id="contexla-auth" class="min-h-dvh bg-[#0f1330] text-text">
        <div class="grid min-h-dvh w-full lg:grid-cols-2">
          <section class="home-auth-form-panel flex min-h-dvh flex-col bg-surface px-6 py-7 sm:px-10 lg:px-14 xl:px-20">
            <header class="flex items-center justify-between gap-4">
              <a href="/" class="flex items-center gap-3">
                <Layouts.brand_mark class="size-9" />
                <span class="font-display text-xl font-semibold tracking-[-0.02em]">Contexla</span>
              </a>
              <div class="flex items-center rounded-xl border border-border bg-surface-raised p-1">
                <button
                  type="button"
                  data-theme-choice="light"
                  class="rounded-lg px-3 py-1.5 text-xs font-semibold text-primary aria-pressed:bg-surface"
                >Light</button>
                <button
                  type="button"
                  data-theme-choice="dark"
                  class="rounded-lg px-3 py-1.5 text-xs font-medium text-text-muted aria-pressed:bg-surface aria-pressed:text-primary"
                >Dark</button>
              </div>
            </header>

            <div class="home-auth-form-content flex flex-1 items-center py-12">
              <div class="mx-auto w-full max-w-[430px]">
                <div class="home-auth-intro mb-9">
                  <p class="home-auth-eyebrow mb-3 text-sm font-semibold text-[#5842f6]">
                    {if @current_scope, do: "Security check", else: "Your content operations platform"}
                  </p>
                  <h1 class="home-auth-title font-display text-[2.45rem] leading-[1.08] font-semibold tracking-[-0.04em] sm:text-5xl">
                    {if @current_scope, do: "Confirm it’s you", else: "Welcome to Contexla"}
                  </h1>
                  <p class="home-auth-copy mt-4 max-w-sm text-[1.05rem] leading-7 text-text-muted">
                    <%= if @current_scope do %>
                      Enter your password again before accessing sensitive account settings.
                    <% else %>
                      Use the administrator credentials provisioned for this installation.
                    <% end %>
                  </p>
                </div>

                <.form
                  for={@form}
                  id="login_form_password"
                  action={~p"/users/log-in"}
                  phx-submit="submit_password"
                  phx-trigger-action={@trigger_submit}
                  class="space-y-4"
                >
                  <.input
                    readonly={!!@current_scope}
                    field={@form[:email]}
                    type="email"
                    label="Email address"
                    autocomplete="username"
                    spellcheck="false"
                    required
                    class="input-field h-14 px-4 text-base"
                  />
                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Password"
                    autocomplete="current-password"
                    spellcheck="false"
                    required
                    class="input-field h-14 px-4 text-base"
                  />
                  <.button
                    class="btn btn-primary h-13 w-full text-base"
                    name={@form[:remember_me].name}
                    value="true"
                  >
                    Log in and stay logged in <span aria-hidden="true">→</span>
                  </.button>
                  <.button class="btn btn-soft h-12 w-full">Log in only this time</.button>
                </.form>
              </div>
            </div>

            <footer class="text-xs text-text-muted">© {Date.utc_today().year} Contexla</footer>
          </section>

          <aside class="home-auth-showcase relative hidden min-h-dvh overflow-hidden bg-[#0f1330] px-12 py-14 text-white lg:flex lg:flex-col xl:px-20">
            <div class="absolute -right-28 -top-36 size-[420px] rounded-full bg-[#885cf6]/30 blur-3xl">
            </div>
            <div class="absolute -bottom-40 -left-32 size-[440px] rounded-full bg-[#ff6a4d]/20 blur-3xl">
            </div>
            <div class="relative flex justify-end">
              <span class="rounded-full border border-white/15 bg-white/5 px-4 py-2 text-xs font-medium tracking-wide text-white/75">Reliable runtime. Adaptable operations.</span>
            </div>
            <div class="home-auth-showcase-content relative flex flex-1 items-center py-10 xl:py-14">
              <div class="mx-auto w-full max-w-xl">
                <div class="mb-8 flex -space-x-2" aria-hidden="true">
                  <span class="grid size-12 place-items-center rounded-full border-2 border-[#0f1330] bg-[#5842f6]"><.icon
                    name="hero-circle-stack"
                    class="size-5"
                  /></span>
                  <span class="grid size-12 place-items-center rounded-full border-2 border-[#0f1330] bg-[#8b5cf6]"><.icon
                    name="hero-arrows-right-left"
                    class="size-5"
                  /></span>
                  <span class="grid size-12 place-items-center rounded-full border-2 border-[#0f1330] bg-[#ff6a4d]"><.icon
                    name="hero-check-badge"
                    class="size-5"
                  /></span>
                </div>
                <p class="home-auth-showcase-title font-display text-4xl leading-tight font-medium tracking-[-0.035em] xl:text-[3.3rem]">
                  Digital content work moves forward when evidence stays connected.
                </p>
                <div class="mt-8 h-px w-20 bg-gradient-to-r from-[#885cf6] to-[#ff6a4d]"></div>
                <p class="mt-6 max-w-lg text-base leading-7 text-white/62">
                  Inspect, validate, transform, and preserve content through focused Applications on one dependable platform.
                </p>
                <ul class="mt-8 grid gap-5">
                  <.benefit icon="hero-squares-2x2" title="Focused Applications">
                    Use purpose-built Applications without creating disconnected tools.
                  </.benefit>
                  <.benefit icon="hero-link" title="Traceable evidence">
                    Keep findings, sources, Runs, and decisions connected.
                  </.benefit>
                  <.benefit icon="hero-cpu-chip" title="Automation with control">
                    Let agents assist while deterministic execution remains authoritative.
                  </.benefit>
                </ul>
              </div>
            </div>
          </aside>
        </div>
      </main>
    </Layouts.app>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp benefit(assigns) do
    ~H"""
    <li class="flex items-start gap-4">
      <span class="flex size-8 shrink-0 items-center justify-center text-[#a99afb]"><.icon
        name={@icon}
        class="size-6"
      /></span>
      <div>
        <p class="font-semibold text-white">{@title}</p>
        <p class="mt-1 text-sm leading-6 text-white/55">{render_slot(@inner_block)}</p>
      </div>
    </li>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
