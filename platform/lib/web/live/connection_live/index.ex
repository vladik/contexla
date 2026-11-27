defmodule Contexla.Platform.Web.ConnectionLive.Index do
  use Contexla.Platform.Web, :live_view

  alias Contexla.Platform.Connections
  alias Contexla.Platform.Connections.Connection
  alias Contexla.Platform.Gateway

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Connections")
     |> assign(:connections, Connections.list_connections())
     |> assign(:conn_form_state, nil)
     |> assign(:conn_editing, nil)
     |> assign(:conn_form, nil)
     |> assign(:conn_adapter_key, "generic_http_json")
     |> assign(:conn_auth_type, "none")}
  end

  @impl true
  def handle_event("new_conn", _, socket) do
    {:noreply,
     socket
     |> assign(:conn_form_state, :new)
     |> assign(:conn_adapter_key, "generic_http_json")
     |> assign(:conn_auth_type, "none")
     |> assign(:conn_editing, %Connection{})
     |> assign(:conn_form, to_form(Connection.changeset(%Connection{}, %{})))}
  end

  def handle_event("edit_conn", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    auth_type = (connection.credentials || %{})["auth_type"] || "none"

    {:noreply,
     socket
     |> assign(:conn_form_state, :edit)
     |> assign(:conn_adapter_key, connection.adapter_key)
     |> assign(:conn_auth_type, auth_type)
     |> assign(:conn_editing, connection)
     |> assign(:conn_form, to_form(Connection.changeset(connection, %{})))}
  end

  def handle_event("cancel_conn", _, socket) do
    {:noreply, close_form(socket)}
  end

  def handle_event("set_conn_adapter", %{"adapter_key" => key}, socket) do
    {:noreply,
     socket
     |> assign(:conn_adapter_key, key)
     |> assign(:conn_auth_type, "none")}
  end

  def handle_event("validate_conn", %{"connection" => params}, socket) do
    auth_type = get_in(params, ["credentials", "auth_type"]) || "none"

    changeset =
      socket.assigns.conn_editing
      |> Connection.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:conn_form, to_form(changeset))
     |> assign(:conn_auth_type, auth_type)}
  end

  def handle_event("save_conn", %{"connection" => params}, socket) do
    params = maybe_merge_credentials(socket.assigns.conn_form_state, socket.assigns.conn_editing, params)

    result =
      case socket.assigns.conn_form_state do
        :new -> Connections.create_connection(params)
        :edit -> Connections.update_connection(socket.assigns.conn_editing, params)
      end

    case result do
      {:ok, _connection} ->
        {:noreply,
         socket
         |> assign(:connections, Connections.list_connections())
         |> close_form()}

      {:error, changeset} ->
        {:noreply, assign(socket, :conn_form, to_form(changeset))}
    end
  end

  def handle_event("delete_conn", %{"id" => id}, socket) do
    connection = Connections.get_connection!(id)
    {:ok, _} = Connections.delete_connection(connection)
    {:noreply, assign(socket, :connections, Connections.list_connections())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.surface>
        <:header>
          <.header id="connections-page-header" icon="hero-link">
            Connections
            <:subtitle>Configured access to external systems, shared across all Application Instances</:subtitle>
            <:actions>
              <UIButton.button phx-click="new_conn" variant="primary" size="sm">
                <.icon name="hero-plus" class="size-4" /> New Connection
              </UIButton.button>
            </:actions>
          </.header>
        </:header>

        <%!-- Form panel --%>
        <div
          :if={@conn_form_state != nil}
          class="mb-5 rounded-2xl border border-border bg-surface p-5"
        >
          <h2 class="mb-4 text-sm font-semibold text-text">
            {if @conn_form_state == :new, do: "New connection", else: "Edit: #{@conn_editing.name}"}
          </h2>

          <%!-- Adapter selector (outside main form — resets credential fields) --%>
          <form phx-change="set_conn_adapter" class="mb-5">
            <label class="mb-1.5 block text-sm font-medium text-text-muted">System type</label>
            <select
              name="adapter_key"
              class="block w-full max-w-sm rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
            >
              <option
                :for={{key, label} <- Gateway.available_adapters()}
                value={key}
                selected={@conn_adapter_key == key}
              >
                {label}
              </option>
            </select>
          </form>

          <.form
            for={@conn_form}
            phx-change="validate_conn"
            phx-submit="save_conn"
            class="space-y-4"
          >
            <input type="hidden" name="connection[adapter_key]" value={@conn_adapter_key} />

            <div class="grid gap-4 sm:grid-cols-2">
              <.input field={@conn_form[:name]} label="Name" placeholder="ERP Production" />
              <.input
                field={@conn_form[:description]}
                label="Description"
                placeholder="Optional notes about this connection"
              />
            </div>

            <.input
              field={@conn_form[:base_url]}
              label="Base URL"
              placeholder="https://api.example.com"
            />

            <%!-- Auth type selector --%>
            <div>
              <label class="mb-1.5 block text-sm font-medium text-text-muted">Authentication</label>
              <select
                name="connection[credentials][auth_type]"
                class="block w-full max-w-sm rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
              >
                <option
                  :for={{label, value} <- auth_type_options(@conn_adapter_key)}
                  value={value}
                  selected={@conn_auth_type == value}
                >
                  {label}
                </option>
              </select>
            </div>

            <%!-- Bearer token --%>
            <div :if={@conn_auth_type == "bearer"}>
              <label class="mb-1.5 block text-sm font-medium text-text-muted">Token</label>
              <input
                type="password"
                name="connection[credentials][token]"
                value=""
                placeholder={if @conn_form_state == :edit, do: "Leave blank to keep existing", else: "Bearer token value"}
                autocomplete="off"
                class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
            </div>

            <%!-- Basic auth --%>
            <div :if={@conn_auth_type == "basic"} class="grid gap-4 sm:grid-cols-2">
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Username</label>
                <input
                  type="text"
                  name="connection[credentials][username]"
                  value={existing_credential(@conn_editing, @conn_form_state, "username")}
                  placeholder="Username"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Password</label>
                <input
                  type="password"
                  name="connection[credentials][password]"
                  value=""
                  placeholder={if @conn_form_state == :edit, do: "Leave blank to keep existing", else: "Password"}
                  autocomplete="off"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
            </div>

            <%!-- API key — header --%>
            <div :if={@conn_auth_type == "api_key_header"} class="grid gap-4 sm:grid-cols-2">
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Header name</label>
                <input
                  type="text"
                  name="connection[credentials][header_name]"
                  value={existing_credential(@conn_editing, @conn_form_state, "header_name")}
                  placeholder="X-API-Key"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Header value</label>
                <input
                  type="password"
                  name="connection[credentials][header_value]"
                  value=""
                  placeholder={if @conn_form_state == :edit, do: "Leave blank to keep existing", else: "Key value"}
                  autocomplete="off"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
            </div>

            <%!-- API key — query param --%>
            <div :if={@conn_auth_type == "api_key_query"} class="grid gap-4 sm:grid-cols-2">
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Parameter name</label>
                <input
                  type="text"
                  name="connection[credentials][param_name]"
                  value={existing_credential(@conn_editing, @conn_form_state, "param_name")}
                  placeholder="api_key"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
              <div>
                <label class="mb-1.5 block text-sm font-medium text-text-muted">Parameter value</label>
                <input
                  type="password"
                  name="connection[credentials][param_value]"
                  value=""
                  placeholder={if @conn_form_state == :edit, do: "Leave blank to keep existing", else: "Key value"}
                  autocomplete="off"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                />
              </div>
            </div>

            <div class="flex items-center gap-3 pt-1">
              <UIButton.button type="submit" variant="primary" size="sm">Save</UIButton.button>
              <UIButton.button type="button" phx-click="cancel_conn" variant="ghost" size="sm">
                Cancel
              </UIButton.button>
            </div>
          </.form>
        </div>

        <%!-- Connections list --%>
        <div class="overflow-hidden rounded-2xl border border-border bg-surface">
          <div class="border-b border-border px-4 py-3 sm:px-5">
            <h2 class="text-sm font-semibold text-text">Connected Systems</h2>
            <p class="mt-0.5 text-xs text-text-muted">
              Reusable connections referenced by Sources and Targets in any monitor
            </p>
          </div>
          <div class="divide-y divide-border">
            <div
              :for={conn <- @connections}
              class="flex items-center justify-between gap-4 px-4 py-3 sm:px-5"
            >
              <div class="flex min-w-0 items-center gap-3">
                <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-surface-raised text-text-muted">
                  <.icon name="hero-link" class="size-4" />
                </span>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-text">{conn.name}</p>
                  <p class="mt-0.5 truncate text-xs text-text-muted">
                    {adapter_label(conn.adapter_key)} · {conn.base_url}
                  </p>
                </div>
              </div>
              <div class="flex shrink-0 items-center gap-2">
                <UIButton.button
                  phx-click="edit_conn"
                  phx-value-id={conn.id}
                  variant="ghost"
                  size="sm"
                >
                  Edit
                </UIButton.button>
                <UIButton.button
                  phx-click="delete_conn"
                  phx-value-id={conn.id}
                  variant="ghost"
                  size="sm"
                  data-confirm="Delete this connection? Sources using it will stop working."
                >
                  Delete
                </UIButton.button>
              </div>
            </div>
            <div :if={@connections == []} class="py-12 text-center">
              <.icon name="hero-link-slash" class="mx-auto mb-3 size-8 text-text-muted/50" />
              <p class="text-sm font-medium text-text">No connections yet</p>
              <p class="mt-1 text-xs text-text-muted">
                Add a connection to let monitors reach external systems.
              </p>
            </div>
          </div>
        </div>
      </.surface>
    </Layouts.app>
    """
  end

  defp close_form(socket) do
    socket
    |> assign(:conn_form_state, nil)
    |> assign(:conn_editing, nil)
    |> assign(:conn_form, nil)
    |> assign(:conn_adapter_key, "generic_http_json")
    |> assign(:conn_auth_type, "none")
  end

  defp auth_type_options(adapter_key) do
    Gateway.connection_fields(adapter_key)
    |> Enum.find(&(&1.key == :auth_type))
    |> case do
      nil -> [{"None", "none"}]
      field -> field.options
    end
  end

  defp adapter_label(adapter_key) do
    Gateway.available_adapters()
    |> Enum.find(fn {key, _} -> key == adapter_key end)
    |> case do
      {_, label} -> label
      nil -> adapter_key
    end
  end

  defp existing_credential(nil, _, _), do: ""
  defp existing_credential(_, :new, _), do: ""

  defp existing_credential(connection, :edit, key) do
    (connection.credentials || %{})[key] || ""
  end

  defp maybe_merge_credentials(:new, _, params), do: params

  defp maybe_merge_credentials(:edit, existing_conn, params) do
    existing_creds = (existing_conn.credentials || %{})
    new_creds = params["credentials"] || %{}

    merged =
      Map.merge(existing_creds, Map.reject(new_creds, fn {_k, v} -> v == "" end))

    Map.put(params, "credentials", merged)
  end
end
