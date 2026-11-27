defmodule Contexla.Applications.ContentIntegrityMonitor.Web.CollectionLive do
  use Contexla.Ui.ContexlaUi, :live_view

  alias Contexla.Applications.Sdk.{Instance, Runtime}

  alias Contexla.Applications.ContentIntegrityMonitor.{
    Fact,
    Monitor,
    ScheduleWindow,
    Source
  }

  alias Contexla.Applications.ContentIntegrityMonitor.Monitors

  @impl true
  def mount(_params, %{"instance" => data}, socket) do
    instance = Instance.from_session!(data)
    monitors = Monitors.list_monitors(instance)
    archived_monitors = Monitors.list_archived_monitors(instance)

    {:ok,
     assign(socket,
       instance: instance,
       monitors: monitors,
       archived_monitors: archived_monitors,
       view: :list,
       active_tab: :general,
       selected_monitor: nil,
       monitor_form: nil,
       # Tags (managed separately from monitor form)
       current_tags: [],
       # Scope tab
       scope_form: nil,
       scope_editing: false,
       scope_adapter_type: "http_json",
       # Facts tab
       fact_form_state: nil,
       fact_form: nil,
       confirm_delete_fact_id: nil,
       # Source tab
       source_form: nil,
       source_form_state: nil,
       source_adapter_type: "http_json_per_entity",
       source_mapping_rows: [],
       confirm_delete_source_id: nil,
       # Target tab
       target_form_state: nil,
       target_form: nil,
       target_adapter_type: "http_json_per_entity",
       target_mapping_rows: [],
       target_profile_rows: [],
       confirm_delete_target_id: nil,
       # Schedule tab
       schedule_form: nil,
       window_form_state: nil,
       window_form: nil,
       # Mapping JSON view toggles
       source_mapping_json_view: false,
       target_mapping_json_view: false
     )}
  end

  # -- Navigation --

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab_atom = String.to_existing_atom(tab)
    socket = initialize_tab(socket, tab_atom)
    {:noreply, assign(socket, active_tab: tab_atom)}
  end

  def handle_event("new_monitor", _params, socket) do
    {:noreply,
     assign(socket,
       view: :monitor,
       active_tab: :general,
       selected_monitor: nil,
       monitor_form: new_monitor_form(),
       current_tags: [],
       scope_form: nil,
       scope_editing: false,
       scope_adapter_type: "http_json",
       fact_form_state: nil,
       fact_form: nil,
       source_form: nil,
       source_form_state: nil,
       source_adapter_type: "http_json_per_entity",
       source_mapping_rows: [],
       target_form_state: nil,
       target_form: nil,
       target_adapter_type: "http_json_per_entity",
       target_mapping_rows: [],
       target_profile_rows: [],
       schedule_form: nil,
       window_form_state: nil,
       window_form: nil,
       source_mapping_json_view: false,
       target_mapping_json_view: false
     )}
  end

  def handle_event("edit_monitor", %{"id" => id}, socket) do
    case Monitors.get_monitor(socket.assigns.instance, id) do
      {:ok, monitor} ->
        {:noreply,
         assign(socket,
           view: :monitor,
           active_tab: :general,
           selected_monitor: monitor,
           monitor_form: monitor_form_from(monitor),
           current_tags: tags_from_monitor(monitor),
           scope_form: nil,
           scope_editing: false,
           scope_adapter_type: "http_json",
           fact_form_state: nil,
           fact_form: nil,
           source_form: nil,
           source_form_state: nil,
           source_adapter_type: "http_json_per_entity",
           source_mapping_rows: [],
           target_form_state: nil,
           target_form: nil,
           target_adapter_type: "http_json_per_entity",
           target_mapping_rows: [],
           schedule_form: schedule_form_from(monitor),
           window_form_state: nil,
           window_form: nil,
           source_mapping_json_view: false,
           target_mapping_json_view: false
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Monitor not found.")}
    end
  end

  def handle_event("back_to_list", _params, socket) do
    {:noreply, socket |> load_monitor_lists() |> assign(view: :list, selected_monitor: nil)}
  end

  # -- General tab --

  def handle_event("validate_monitor", %{"monitor" => attrs}, socket) do
    attrs = Map.put(attrs, "application_instance_id", socket.assigns.instance.id)

    changeset =
      case socket.assigns.selected_monitor do
        nil -> Monitor.changeset(%Monitor{}, attrs)
        m -> Monitor.changeset(m, attrs)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, monitor_form: to_form(changeset, as: :monitor))}
  end

  def handle_event("save_monitor", %{"monitor" => attrs}, socket) do
    instance = socket.assigns.instance
    entity_type = socket.assigns.current_tags |> Enum.join(", ")
    attrs = Map.put(attrs, "entity_type", entity_type)

    result =
      case socket.assigns.selected_monitor do
        nil -> Monitors.create_monitor(instance, attrs)
        m -> Monitors.update_monitor(instance, m.id, attrs)
      end

    case result do
      {:ok, monitor} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Monitor saved.")
         |> assign(
           selected_monitor: refreshed,
           monitor_form: monitor_form_from(refreshed),
           schedule_form: schedule_form_from(refreshed)
         )}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, monitor_form: to_form(cs, as: :monitor))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save monitor: #{inspect(reason)}.")}
    end
  end

  def handle_event("archive_monitor", %{"id" => id}, socket) do
    case Monitors.archive_monitor(socket.assigns.instance, id) do
      :ok ->
        {:noreply,
         socket
         |> load_monitor_lists()
         |> put_flash(:info, "Monitor archived.")
         |> assign(view: :list, selected_monitor: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not archive monitor.")}
    end
  end

  def handle_event("restore_monitor", %{"id" => id}, socket) do
    case Monitors.restore_monitor(socket.assigns.instance, id) do
      :ok ->
        {:noreply,
         socket
         |> load_monitor_lists()
         |> put_flash(:info, "Monitor restored.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not restore monitor.")}
    end
  end

  def handle_event("run_monitor", %{"id" => monitor_id}, socket) do
    instance = socket.assigns.instance

    case Runtime.invoke_operation(instance.actor_id, instance.id, "integrity.run", %{
           "monitor_id" => monitor_id
         }) do
      {:ok, _result, _invocation} ->
        {:noreply, put_flash(socket, :info, "Run queued.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Could not start the run.")}
    end
  end

  # -- Tag events --

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    tag = String.trim(tag)

    if tag == "" do
      {:noreply, socket}
    else
      tags = socket.assigns.current_tags
      tags = if tag in tags, do: tags, else: tags ++ [tag]
      {:noreply, assign(socket, current_tags: tags)}
    end
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    tags = Enum.reject(socket.assigns.current_tags, &(&1 == tag))
    {:noreply, assign(socket, current_tags: tags)}
  end

  # -- Adapter picker events --

  def handle_event("set_scope_adapter", %{"type" => type}, socket) do
    {:noreply, assign(socket, scope_adapter_type: type)}
  end

  def handle_event("set_source_adapter", %{"type" => type}, socket) do
    {:noreply, assign(socket, source_adapter_type: type)}
  end

  def handle_event("set_target_adapter", %{"type" => type}, socket) do
    {:noreply, assign(socket, target_adapter_type: type)}
  end

  def handle_event("toggle_source_mapping_json", _params, socket) do
    {:noreply, assign(socket, source_mapping_json_view: !socket.assigns.source_mapping_json_view)}
  end

  def handle_event("toggle_target_mapping_json", _params, socket) do
    {:noreply,
     assign(socket, target_mapping_json_view: !socket.assigns.target_mapping_json_view)}
  end

  # -- Scope tab --

  def handle_event("edit_scope", _params, socket) do
    monitor = socket.assigns.selected_monitor
    scope = scope_source(monitor)
    form = if scope, do: source_form_from(scope), else: new_scope_form()
    adapter = if scope, do: adapter_type_from_scope(scope), else: socket.assigns.scope_adapter_type

    {:noreply, assign(socket, scope_editing: true, scope_form: form, scope_adapter_type: adapter)}
  end

  def handle_event("cancel_scope", _params, socket) do
    {:noreply, assign(socket, scope_editing: false)}
  end

  def handle_event("validate_scope", %{"source" => attrs}, socket) do
    monitor = socket.assigns.selected_monitor
    scope = scope_source(monitor)
    adapter_attrs = adapter_to_attrs(socket.assigns.scope_adapter_type)

    attrs =
      attrs
      |> Map.put("monitor_id", monitor.id)
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)
      |> Map.put("mappings", %{})

    changeset =
      (scope || %Source{})
      |> Source.changeset(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, scope_form: to_form(changeset, as: :source))}
  end

  def handle_event("save_scope", %{"source" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor
    adapter = socket.assigns.scope_adapter_type
    adapter_attrs = adapter_to_attrs(adapter)

    attrs =
      attrs
      |> Map.put("role", "scope")
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)
      |> Map.put("mappings", %{})
      |> Map.put_new_lazy("key", fn -> slugify(attrs["name"] || "scope") end)

    # Manual adapter: entity refs come from static_refs, not a URL
    attrs = if adapter == "manual", do: Map.put(attrs, "url", nil), else: attrs

    result =
      case scope_source(monitor) do
        nil -> Monitors.add_source(instance, monitor.id, attrs)
        source -> Monitors.update_source(instance, source.id, attrs)
      end

    case result do
      {:ok, _source} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Scope saved.")
         |> assign(selected_monitor: refreshed, scope_editing: false)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, scope_form: to_form(cs, as: :source))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save scope: #{inspect(reason)}.")}
    end
  end

  # -- Facts tab --

  def handle_event("new_fact", _params, socket) do
    {:noreply, assign(socket, fact_form_state: :new, fact_form: new_fact_form())}
  end

  def handle_event("edit_fact", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.selected_monitor.facts, &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Fact not found.")}

      fact ->
        {:noreply, assign(socket, fact_form_state: {:edit, id}, fact_form: fact_form_from(fact))}
    end
  end

  def handle_event("cancel_fact", _params, socket) do
    {:noreply, assign(socket, fact_form_state: nil, fact_form: nil)}
  end

  def handle_event("validate_fact", %{"fact" => attrs}, socket) do
    monitor = socket.assigns.selected_monitor

    {fact, attrs} =
      case socket.assigns.fact_form_state do
        :new ->
          key =
            if attrs["key"] not in [nil, ""], do: attrs["key"], else: slugify(attrs["name"] || "")

          {nil, attrs |> Map.put("monitor_id", monitor.id) |> Map.put("key", key)}

        {:edit, id} ->
          existing = Enum.find(monitor.facts, &(&1.id == id))

          key =
            cond do
              attrs["key"] not in [nil, ""] -> attrs["key"]
              existing -> existing.key
              true -> slugify(attrs["name"] || "")
            end

          {existing, attrs |> Map.put("monitor_id", monitor.id) |> Map.put("key", key)}

        _ ->
          {nil, Map.put(attrs, "monitor_id", monitor.id)}
      end

    changeset = (fact || %Fact{}) |> Fact.changeset(attrs) |> Map.put(:action, :validate)
    {:noreply, assign(socket, fact_form: to_form(changeset, as: :fact))}
  end

  def handle_event("save_fact", %{"fact" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor

    attrs =
      case socket.assigns.fact_form_state do
        :new ->
          key =
            if attrs["key"] not in [nil, ""], do: attrs["key"], else: slugify(attrs["name"] || "")

          Map.put(attrs, "key", key)

        {:edit, _id} ->
          attrs
      end

    result =
      case socket.assigns.fact_form_state do
        :new -> Monitors.add_fact(instance, monitor.id, attrs)
        {:edit, id} -> Monitors.update_fact(instance, id, attrs)
      end

    case result do
      {:ok, _fact} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Fact saved.")
         |> assign(selected_monitor: refreshed, fact_form_state: nil, fact_form: nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, fact_form: to_form(cs, as: :fact))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save fact: #{inspect(reason)}.")}
    end
  end

  def handle_event("delete_fact", %{"id" => id}, socket) do
    case Monitors.delete_fact(socket.assigns.instance, id) do
      :ok ->
        {:ok, refreshed} =
          Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Fact deleted.")
         |> assign(selected_monitor: refreshed, fact_form_state: nil, fact_form: nil, confirm_delete_fact_id: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete fact.")}
    end
  end

  # -- Source tab --

  def handle_event("new_source", _params, socket) do
    monitor = socket.assigns.selected_monitor
    rows = build_mapping_rows(monitor.facts, %{})

    {:noreply,
     assign(socket,
       source_form_state: :new,
       source_form: new_data_source_form(),
       source_adapter_type: "http_json_per_entity",
       source_mapping_rows: rows
     )}
  end

  def handle_event("edit_source", %{"id" => id}, socket) do
    monitor = socket.assigns.selected_monitor

    case Enum.find(sources(monitor), &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Source not found.")}

      source ->
        mappings = source.mappings || %{}
        rows = build_mapping_rows(monitor.facts, mappings)
        adapter = adapter_type_from(source)

        {:noreply,
         assign(socket,
           source_form_state: {:edit, id},
           source_form: source_form_from(source),
           source_adapter_type: adapter,
           source_mapping_rows: rows
         )}
    end
  end

  def handle_event("cancel_source", _params, socket) do
    {:noreply, assign(socket, source_form_state: nil, source_form: nil)}
  end

  def handle_event("validate_source", %{"source" => attrs}, socket) do
    monitor = socket.assigns.selected_monitor
    adapter_attrs = adapter_to_attrs(socket.assigns.source_adapter_type)

    source =
      case socket.assigns.source_form_state do
        {:edit, id} -> Enum.find(sources(monitor), &(&1.id == id))
        _ -> nil
      end

    attrs =
      attrs
      |> Map.put("monitor_id", monitor.id)
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)

    changeset =
      (source || %Source{})
      |> Source.changeset(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, source_form: to_form(changeset, as: :source))}
  end

  def handle_event("save_source", %{"source" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor
    adapter_attrs = adapter_to_attrs(socket.assigns.source_adapter_type)
    mappings = mappings_from_rows(socket.assigns.source_mapping_rows)

    attrs =
      attrs
      |> Map.put("role", "source")
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)
      |> Map.put("mappings", mappings)
      |> Map.put_new_lazy("key", fn -> slugify(attrs["name"] || "source") end)

    result =
      case socket.assigns.source_form_state do
        :new -> Monitors.add_source(instance, monitor.id, attrs)
        {:edit, id} -> Monitors.update_source(instance, id, attrs)
      end

    case result do
      {:ok, _source} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Source saved.")
         |> assign(selected_monitor: refreshed, source_form_state: nil, source_form: nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, source_form: to_form(cs, as: :source))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save source: #{inspect(reason)}.")}
    end
  end

  def handle_event("delete_source", %{"id" => id}, socket) do
    case Monitors.delete_source(socket.assigns.instance, id) do
      :ok ->
        {:ok, refreshed} =
          Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Source deleted.")
         |> assign(selected_monitor: refreshed, source_form_state: nil, source_form: nil, confirm_delete_source_id: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete source.")}
    end
  end

  def handle_event("update_source_mapping", %{"key" => key, "value" => path}, socket) do
    rows =
      Enum.map(socket.assigns.source_mapping_rows, fn
        {k, name, _} when k == key -> {k, name, path}
        row -> row
      end)

    {:noreply, assign(socket, source_mapping_rows: rows)}
  end

  # -- Target tab --

  def handle_event("new_target", _params, socket) do
    monitor = socket.assigns.selected_monitor
    rows = build_mapping_rows(monitor.facts, %{})
    profile_rows = build_target_profile_rows(monitor.facts, [])

    {:noreply,
     assign(socket,
       target_form_state: :new,
       target_form: new_data_source_form(),
       target_adapter_type: "http_json_per_entity",
       target_mapping_rows: rows,
       target_profile_rows: profile_rows
     )}
  end

  def handle_event("edit_target", %{"id" => id}, socket) do
    monitor = socket.assigns.selected_monitor

    case Enum.find(targets(monitor), &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Source not found.")}

      source ->
        mappings = source.mappings || %{}
        rows = build_mapping_rows(monitor.facts, mappings)
        profile_rows = build_target_profile_rows(monitor.facts, source.target_fact_profiles)
        adapter = adapter_type_from(source)

        {:noreply,
         assign(socket,
           target_form_state: {:edit, id},
           target_form: source_form_from(source),
           target_adapter_type: adapter,
           target_mapping_rows: rows,
           target_profile_rows: profile_rows
         )}
    end
  end

  def handle_event("cancel_target", _params, socket) do
    {:noreply, assign(socket, target_form_state: nil, target_form: nil, target_profile_rows: [])}
  end

  def handle_event("update_target_profile", params, socket) do
    fact_id = params["fact_id"]
    expected = params["expected"]
    comparison_type = params["comparison_type"]

    updated =
      Enum.map(socket.assigns.target_profile_rows, fn
        {^fact_id, key, name, _exp, _comp} ->
          exp = if expected, do: String.to_existing_atom(expected), else: :required
          comp = if comparison_type && comparison_type != "", do: String.to_existing_atom(comparison_type), else: nil
          {fact_id, key, name, exp, comp}
        row ->
          row
      end)

    {:noreply, assign(socket, target_profile_rows: updated)}
  end

  def handle_event("validate_target", %{"source" => attrs}, socket) do
    monitor = socket.assigns.selected_monitor
    adapter_attrs = adapter_to_attrs(socket.assigns.target_adapter_type)

    source =
      case socket.assigns.target_form_state do
        {:edit, id} -> Enum.find(targets(monitor), &(&1.id == id))
        _ -> nil
      end

    attrs =
      attrs
      |> Map.put("monitor_id", monitor.id)
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)

    changeset =
      (source || %Source{})
      |> Source.changeset(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, target_form: to_form(changeset, as: :source))}
  end

  def handle_event("save_target", %{"source" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor
    adapter_attrs = adapter_to_attrs(socket.assigns.target_adapter_type)
    mappings = mappings_from_rows(socket.assigns.target_mapping_rows)

    attrs =
      attrs
      |> Map.put("role", "target")
      |> Map.put("format", adapter_attrs.format)
      |> Map.put("fetch_strategy", adapter_attrs.fetch_strategy)
      |> Map.put("mappings", mappings)
      |> Map.put_new_lazy("key", fn -> "target_#{:erlang.unique_integer([:positive])}" end)

    result =
      case socket.assigns.target_form_state do
        :new -> Monitors.add_source(instance, monitor.id, attrs)
        {:edit, id} -> Monitors.update_source(instance, id, attrs)
      end

    case result do
      {:ok, saved_source} ->
        profiles = Enum.map(socket.assigns.target_profile_rows, fn {fact_id, _key, _name, expected, comparison_type} ->
          {fact_id, expected, comparison_type}
        end)

        Monitors.upsert_target_fact_profiles(instance, saved_source.id, profiles)

        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Target saved.")
         |> assign(selected_monitor: refreshed, target_form_state: nil, target_form: nil, target_profile_rows: [])}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, target_form: to_form(cs, as: :source))}

      {:error, reason} ->
        {:noreply,
         put_flash(socket, :error, "Could not save target: #{inspect(reason)}.")}
    end
  end

  def handle_event("delete_target", %{"id" => id}, socket) do
    case Monitors.delete_source(socket.assigns.instance, id) do
      :ok ->
        {:ok, refreshed} =
          Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Target deleted.")
         |> assign(selected_monitor: refreshed, target_form_state: nil, target_form: nil, confirm_delete_target_id: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete target.")}
    end
  end

  def handle_event("confirm_delete_source", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete_source_id: id, confirm_delete_target_id: nil)}
  end

  def handle_event("cancel_delete_source", _params, socket) do
    {:noreply, assign(socket, confirm_delete_source_id: nil)}
  end

  def handle_event("confirm_delete_target", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete_target_id: id, confirm_delete_source_id: nil)}
  end

  def handle_event("cancel_delete_target", _params, socket) do
    {:noreply, assign(socket, confirm_delete_target_id: nil)}
  end

  def handle_event("confirm_delete_fact", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete_fact_id: id)}
  end

  def handle_event("cancel_delete_fact", _params, socket) do
    {:noreply, assign(socket, confirm_delete_fact_id: nil)}
  end

  def handle_event("move_source", %{"id" => id, "direction" => dir}, socket) do
    direction = if dir == "up", do: :up, else: :down

    case Monitors.move_source(socket.assigns.instance, id, direction) do
      :ok ->
        {:ok, refreshed} = Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)
        {:noreply, assign(socket, selected_monitor: refreshed)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reorder.")}
    end
  end

  def handle_event("move_target", %{"id" => id, "direction" => dir}, socket) do
    direction = if dir == "up", do: :up, else: :down

    case Monitors.move_source(socket.assigns.instance, id, direction) do
      :ok ->
        {:ok, refreshed} = Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)
        {:noreply, assign(socket, selected_monitor: refreshed)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not reorder.")}
    end
  end

  def handle_event("update_target_mapping", %{"key" => key, "value" => path}, socket) do
    rows =
      Enum.map(socket.assigns.target_mapping_rows, fn
        {k, name, _} when k == key -> {k, name, path}
        row -> row
      end)

    {:noreply, assign(socket, target_mapping_rows: rows)}
  end

  # -- Schedule tab --

  def handle_event("save_schedule", %{"monitor" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor

    case Monitors.update_monitor(instance, monitor.id, attrs) do
      {:ok, _updated} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Schedule saved.")
         |> assign(selected_monitor: refreshed, schedule_form: schedule_form_from(refreshed))}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, schedule_form: to_form(cs, as: :monitor))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save schedule: #{inspect(reason)}.")}
    end
  end

  def handle_event("new_window", _params, socket) do
    {:noreply, assign(socket, window_form_state: :new, window_form: new_window_form())}
  end

  def handle_event("cancel_window", _params, socket) do
    {:noreply, assign(socket, window_form_state: nil, window_form: nil)}
  end

  def handle_event("save_window", %{"window" => attrs}, socket) do
    instance = socket.assigns.instance
    monitor = socket.assigns.selected_monitor

    case Monitors.add_schedule_window(instance, monitor.id, attrs) do
      {:ok, _window} ->
        {:ok, refreshed} = Monitors.get_monitor(instance, monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Maintenance window saved.")
         |> assign(selected_monitor: refreshed, window_form_state: nil, window_form: nil)}

      {:error, %Ecto.Changeset{} = cs} ->
        {:noreply, assign(socket, window_form: to_form(cs, as: :window))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save window: #{inspect(reason)}.")}
    end
  end

  def handle_event("delete_window", %{"id" => id}, socket) do
    case Monitors.delete_schedule_window(socket.assigns.instance, id) do
      :ok ->
        {:ok, refreshed} =
          Monitors.get_monitor(socket.assigns.instance, socket.assigns.selected_monitor.id)

        {:noreply,
         socket
         |> put_flash(:info, "Window deleted.")
         |> assign(selected_monitor: refreshed)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete window.")}
    end
  end

  # -- Render --

  @impl true
  def render(assigns) do
    ~H"""
    <.application_frame
      id="integrity-monitors"
      icon="hero-shield-check"
      title={@instance.name}
      flash={assigns[:flash]}
    >
      <:navigation>
        <.tabs id="integrity-navigation">
          <:tab label="Overview" icon="hero-home" navigate={"/applications/#{@instance.id}"} />
          <:tab
            label="Monitors"
            icon="hero-signal"
            navigate={"/applications/#{@instance.id}/monitors"}
            selected
          />
        </.tabs>
      </:navigation>

      <%!-- LIST VIEW --%>
      <div :if={@view == :list} class="mt-6 space-y-6">
        <.empty_state
          :if={@monitors == [] && @archived_monitors == []}
          title="No monitors configured"
          description="A monitor checks that specific facts about your entities are consistent across all sources."
        >
          <:actions>
            <.button phx-click="new_monitor" variant="primary">New monitor</.button>
          </:actions>
        </.empty_state>

        <div :if={@monitors != [] || @archived_monitors != []} class="space-y-4">
          <div class="flex justify-end">
            <.button phx-click="new_monitor" variant="primary">New monitor</.button>
          </div>

          <.panel :for={monitor <- @monitors} title={monitor.name} description={monitor.description}>
            <:actions>
              <.button phx-click="edit_monitor" phx-value-id={monitor.id} size="sm" variant="soft">
                Edit
              </.button>
            </:actions>
            <div class="flex flex-wrap items-center gap-2 text-sm text-text-muted">
              <span class={[
                "rounded-full px-2 py-0.5 text-xs font-medium",
                if(monitor.status == :active,
                  do: "bg-success-subtle text-success",
                  else: "bg-surface-raised text-text-muted"
                )
              ]}>
                {String.capitalize(to_string(monitor.status))}
              </span>
              <span :for={tag <- tags_from_monitor(monitor)} class="rounded-full bg-primary-subtle px-2 py-0.5 text-xs text-primary">
                {tag}
              </span>
              <span :if={monitor.cron_expression} class="font-mono text-xs">
                {monitor.cron_expression}
              </span>
            </div>
          </.panel>
        </div>

        <%!-- Archived monitors section --%>
        <div :if={@archived_monitors != []} class="space-y-3">
          <h3 class="text-sm font-medium text-text-muted">Archived monitors</h3>
          <.panel
            :for={monitor <- @archived_monitors}
            title={monitor.name}
            description={monitor.description}
          >
            <:actions>
              <.button
                phx-click="restore_monitor"
                phx-value-id={monitor.id}
                size="sm"
                variant="ghost"
              >
                Restore
              </.button>
            </:actions>
            <div class="flex flex-wrap items-center gap-2 text-sm text-text-muted">
              <span class="rounded-full bg-surface-raised px-2 py-0.5 text-xs font-medium text-text-muted">
                Archived
              </span>
              <span :for={tag <- tags_from_monitor(monitor)} class="rounded-full bg-primary-subtle px-2 py-0.5 text-xs text-primary">
                {tag}
              </span>
            </div>
          </.panel>
        </div>
      </div>

      <%!-- MONITOR VIEW --%>
      <div :if={@view == :monitor} class="mt-6 space-y-4">
        <%!-- Header row --%>
        <div class="flex items-center justify-between">
          <button
            phx-click="back_to_list"
            class="flex items-center gap-1.5 text-sm text-text-muted hover:text-text"
          >
            <.icon name="hero-arrow-left" class="size-4" />
            All monitors
          </button>
          <.button
            :if={@selected_monitor}
            phx-click="run_monitor"
            phx-value-id={@selected_monitor.id}
            size="sm"
            variant="primary"
          >
            Run now
          </.button>
        </div>

        <%!-- Tab bar (only once monitor is saved) --%>
        <div :if={@selected_monitor} class="border-b border-border">
          <nav class="-mb-px flex">
            <button
              :for={
                {tab_id, label} <- [
                  general: "General",
                  scope: "Scope",
                  facts: "Facts",
                  source: "Sources",
                  target: "Targets",
                  schedule: "Schedule"
                ]
              }
              phx-click="set_tab"
              phx-value-tab={tab_id}
              class={[
                "flex items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors",
                if(@active_tab == tab_id,
                  do: "border-primary text-primary",
                  else: "border-transparent text-text-muted hover:text-text"
                )
              ]}
            >
              {label}
              <span
                :if={tab_complete?(@selected_monitor, tab_id)}
                class="inline-flex size-1.5 rounded-full bg-success"
              />
            </button>
          </nav>
        </div>

        <%!-- TAB: General (also shown for new monitor before save) --%>
        <div :if={@active_tab == :general || !@selected_monitor}>
          <.panel title={if @selected_monitor, do: "General", else: "New monitor"}>
            <.form
              id="monitor-form"
              for={@monitor_form}
              phx-change="validate_monitor"
              phx-submit="save_monitor"
              class="space-y-4"
            >
              <.input field={@monitor_form[:name]} label="Name" />

              <div>
                <label class="block text-sm font-medium text-text">
                  Description
                  <span class="ml-1 font-normal text-text-muted">(optional)</span>
                </label>
                <textarea
                  name="monitor[description]"
                  rows="2"
                  placeholder="What does this monitor check?"
                  class="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                >{@monitor_form[:description].value}</textarea>
              </div>
            </.form>

            <%!-- Tags — between Description and Status; own form cannot nest inside monitor form --%>
            <div class="mt-4">
              <.tag_input
                id="monitor-tags"
                tags={@current_tags}
                label="Tags"
                placeholder="Add a tag, press Enter"
              />
            </div>

            <%!-- Status — associated with monitor-form via HTML5 form attribute --%>
            <div class="mb-3 mt-4">
              <label for="monitor-status" class="mb-1 block text-sm font-medium text-text-muted">Status</label>
              <select
                id="monitor-status"
                name="monitor[status]"
                form="monitor-form"
                class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
              >
                <option value="active" selected={to_string(@monitor_form[:status].value) == "active"}>Active</option>
                <option value="disabled" selected={to_string(@monitor_form[:status].value) == "disabled"}>Disabled</option>
              </select>
            </div>

            <div class="flex items-center gap-3 mt-4">
              <button type="submit" form="monitor-form" class="btn btn-primary">
                {if @selected_monitor, do: "Save changes", else: "Create monitor"}
              </button>
              <.button type="button" phx-click="back_to_list" variant="ghost">Cancel</.button>
            </div>
          </.panel>

          <div :if={@selected_monitor} class="mt-4">
            <.panel title="Archive monitor">
              <div class="flex items-center justify-between gap-4">
                <p class="text-sm text-text-muted">
                  Removes this monitor from the active list. No new runs will be queued.
                  You can restore it later.
                </p>
                <.button
                  type="button"
                  phx-click={show_modal("archive-confirm-modal")}
                  size="sm"
                  variant="ghost"
                >
                  Archive
                </.button>
              </div>
            </.panel>
          </div>
        </div>

        <%!-- TAB: Scope --%>
        <div :if={@active_tab == :scope && @selected_monitor}>
          <% scope = scope_source(@selected_monitor) %>
          <.panel
            title="Scope"
            description="Provides the list of entity references this monitor checks. Each entity reference must exist in every source and target."
          >
            <%!-- Scope exists, show summary --%>
            <div :if={scope && !@scope_editing} class="space-y-3">
              <div class="rounded-lg border border-border bg-surface-raised p-4 space-y-1.5">
                <p class="text-sm font-semibold text-text">{scope.name}</p>
                <p class="text-xs font-medium text-text-muted">{scope_adapter_label(scope)}</p>
                <p :if={scope.url && scope.url != ""} class="truncate font-mono text-xs text-text-muted">
                  {scope.url}
                </p>
                <p :if={scope.format == :manual && scope.static_refs} class="text-xs text-text-muted">
                  {length(Jason.decode!(scope.static_refs || "[]"))} entity references configured
                </p>
              </div>
              <.button phx-click="edit_scope" size="sm" variant="soft">Edit</.button>
            </div>

            <%!-- No scope yet or editing --%>
            <div :if={!scope || @scope_editing}>
              <form phx-change="set_scope_adapter" class="mb-4">
                <label class="mb-1 block text-sm font-medium text-text-muted">Adapter</label>
                <select
                  name="type"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
                >
                  <option
                    :for={{label, value} <- scope_adapter_options()}
                    value={value}
                    selected={@scope_adapter_type == value}
                  >
                    {label}
                  </option>
                </select>
              </form>

              <.form
                :if={@scope_form}
                for={@scope_form}
                phx-change="validate_scope"
                phx-submit="save_scope"
                class="space-y-3"
              >
                <.input field={@scope_form[:name]} label="Name" placeholder="e.g. ERP product list" />

                <div :if={@scope_adapter_type in ["http_json", "http_html"]} class="space-y-3">
                  <.input
                    field={@scope_form[:url]}
                    label="URL — returns all entities"
                    placeholder="http://host/api/products"
                  />
                  <.input
                    field={@scope_form[:array_path]}
                    label="Path to entity array in response"
                    placeholder="e.g. products, response.docs"
                  />
                  <.input
                    field={@scope_form[:ref_field]}
                    label="Entity reference field"
                    placeholder="id"
                  />
                </div>

                <div :if={@scope_adapter_type == "manual"}>
                  <label class="block text-sm font-medium text-text">
                    Entity references
                    <span class="ml-1 font-normal text-text-muted">— JSON array of objects</span>
                  </label>
                  <textarea
                    name="source[static_refs]"
                    rows="8"
                    placeholder={"[\n  {\"ref\": \"BCS\", \"lms_id\": \"LMS-BCS-2024\"},\n  {\"ref\": \"MCS\", \"lms_id\": \"LMS-MCS-2024\"}\n]"}
                    class="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                  >{@scope_form[:static_refs].value}</textarea>
                  <p class="mt-1 text-xs text-text-muted">
                    Each object must include the entity reference field. Additional fields are used as source/target lookup keys.
                  </p>
                </div>

                <div :if={@scope_adapter_type == "csv"} class="space-y-3">
                  <.input
                    field={@scope_form[:url]}
                    label="File URL"
                    placeholder="http://host/files/products.csv"
                  />
                  <.input
                    field={@scope_form[:ref_field]}
                    label="Reference column"
                    placeholder="product_id"
                  />
                </div>

                <div class="flex items-center gap-3 pt-1">
                  <.button type="submit" variant="primary" size="sm">Save</.button>
                  <.button
                    :if={scope}
                    type="button"
                    phx-click="cancel_scope"
                    variant="ghost"
                    size="sm"
                  >
                    Cancel
                  </.button>
                </div>
              </.form>
            </div>
          </.panel>
        </div>

        <%!-- TAB: Facts --%>
        <div :if={@active_tab == :facts && @selected_monitor}>
          <.panel
            title="Facts"
            description="Define the facts this monitor tracks. Configure which facts each target must carry in the Targets tab."
          >
            <:actions>
              <.button
                :if={@fact_form_state == nil}
                phx-click="new_fact"
                size="sm"
                variant="soft"
              >
                Add fact
              </.button>
            </:actions>

            <div :if={@fact_form_state != nil} class={[@selected_monitor.facts != [] && "mb-5", "rounded-xl border border-border bg-surface-raised p-4"]}>
              <h3 class="mb-4 text-sm font-semibold text-text">
                {if @fact_form_state == :new, do: "Add fact", else: "Editing: #{@fact_form[:name].value}"}
              </h3>
              <.form
                for={@fact_form}
                phx-change="validate_fact"
                phx-submit="save_fact"
                class="space-y-3"
              >
                <.input field={@fact_form[:name]} label="Name" placeholder="e.g. Product title" />
                <.input
                  field={@fact_form[:key]}
                  label="Key"
                  placeholder={slugify(@fact_form[:name].value || "")}
                />
                <p class="-mt-2 mb-3 text-xs text-text-muted">
                  Auto-generated from name. Used in source and target field mappings.
                </p>
                <div>
                  <label class="mb-1 block text-sm font-medium text-text-muted">
                    Description
                    <span class="ml-1 font-normal text-text-muted">(optional)</span>
                  </label>
                  <textarea
                    name="fact[description]"
                    rows="2"
                    placeholder="What does this fact represent?"
                    class="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                  >{@fact_form[:description].value}</textarea>
                </div>
                <.input
                  field={@fact_form[:comparison_type]}
                  type="select"
                  label="Default comparison"
                  options={[
                    {"Text (exact)", "text"},
                    {"Text (ignore case)", "text_case_insensitive"},
                    {"Numeric", "numeric"},
                    {"Date", "date"}
                  ]}
                />
                <div class="flex items-center gap-3 pt-1">
                  <.button type="submit" variant="primary" size="sm">Save</.button>
                  <.button type="button" phx-click="cancel_fact" variant="ghost" size="sm">Cancel</.button>
                </div>
              </.form>
            </div>

            <div
              :if={@selected_monitor.facts == [] && @fact_form_state == nil}
              class="py-4 text-sm text-text-muted"
            >
              No facts defined. Facts are the values you want to verify across all sources.
            </div>

            <.list
              :if={@selected_monitor.facts != []}
              id={"facts-#{@selected_monitor.id}"}
              rows={@selected_monitor.facts}
              row_id={& &1.id}
              editing_id={editing_id(@fact_form_state)}
            >
              <:row :let={fact}>
                <p class="text-sm font-medium text-text">{fact.name}</p>
                <p :if={fact.description} class="mt-0.5 text-xs text-text-muted">{fact.description}</p>
                <div class="mt-1 flex flex-wrap items-center gap-1.5">
                  <span class="rounded bg-surface-raised px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide text-text-muted">
                    {comparison_type_label(fact.comparison_type)}
                  </span>
                </div>
              </:row>
              <:action :let={fact}>
                <.button
                  :if={@fact_form_state != {:edit, fact.id}}
                  phx-click="edit_fact"
                  phx-value-id={fact.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Edit"
                >
                  <.icon name="hero-pencil" class="size-4" />
                </.button>
                <.button
                  :if={@confirm_delete_fact_id != fact.id}
                  phx-click="confirm_delete_fact"
                  phx-value-id={fact.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Delete"
                >
                  <.icon name="hero-trash" class="size-4" />
                </.button>
                <span :if={@confirm_delete_fact_id == fact.id} class="flex items-center gap-1.5">
                  <span class="text-xs text-text-muted">Delete?</span>
                  <.button phx-click="delete_fact" phx-value-id={fact.id} size="sm" variant="danger-ghost">Yes</.button>
                  <.button phx-click="cancel_delete_fact" size="sm" variant="ghost">No</.button>
                </span>
              </:action>
            </.list>
          </.panel>
        </div>

        <%!-- TAB: Source --%>
        <div :if={@active_tab == :source && @selected_monitor}>
          <.panel
            title="Sources"
            description="Authoritative systems. A fact is read from the first source that has a mapping for it."
          >
            <:actions>
              <.button
                :if={@source_form_state == nil}
                phx-click="new_source"
                size="sm"
                variant="soft"
              >
                Add source
              </.button>
            </:actions>

            <div :if={@source_form_state != nil} class={[sources(@selected_monitor) != [] && "mb-5", "rounded-xl border border-border bg-surface-raised p-4"]}>
              <h3 class="mb-4 text-sm font-semibold text-text">
                {if @source_form_state == :new, do: "Add source", else: "Editing: #{@source_form[:name].value}"}
              </h3>

              <form phx-change="set_source_adapter" class="mb-4">
                <label class="mb-1 block text-sm font-medium text-text-muted">Adapter</label>
                <select
                  name="type"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
                >
                  <option
                    :for={{label, value} <- source_adapter_options()}
                    value={value}
                    selected={@source_adapter_type == value}
                  >
                    {label}
                  </option>
                </select>
              </form>

              <.form
                for={@source_form}
                phx-change="validate_source"
                phx-submit="save_source"
                class="space-y-4"
              >
                <.input field={@source_form[:name]} label="Name" />

                <div :if={@source_adapter_type == "http_json_per_entity"}>
                  <.input
                    field={@source_form[:url]}
                    label="URL — use :ref as the entity reference placeholder"
                    placeholder="http://api.example.com/products/:ref"
                  />
                </div>

                <div :if={@source_adapter_type == "http_json_bulk"} class="space-y-3">
                  <.input field={@source_form[:url]} label="URL — returns all entities" placeholder="http://api.example.com/products" />
                  <.input field={@source_form[:array_path]} label="Path to entity array in response" placeholder="e.g. products, response.docs" />
                  <.input field={@source_form[:ref_field]} label="Reference field" placeholder="id" />
                  <.input field={@source_form[:scope_ref_field]} label="Match against scope field (optional)" placeholder="Leave blank to use scope's reference field" />
                </div>

                <div :if={@source_adapter_type == "http_html"}>
                  <.input
                    field={@source_form[:url]}
                    label="URL — use :ref as the entity reference placeholder"
                    placeholder="http://www.example.com/products/:ref"
                  />
                </div>

                <div :if={@source_adapter_type == "csv"} class="space-y-3">
                  <.input field={@source_form[:url]} label="File URL" placeholder="http://host/files/products.csv" />
                  <.input field={@source_form[:ref_field]} label="Reference column" placeholder="product_id" />
                  <.input field={@source_form[:scope_ref_field]} label="Match against scope field (optional)" placeholder="Leave blank to use scope's reference field" />
                </div>

                <div>
                  <div class="mb-3 flex items-center justify-between">
                    <p class="text-sm font-medium text-text">
                      Field mappings
                      <span class="ml-1 text-xs font-normal text-text-muted">
                        — where in the response each fact value is found
                      </span>
                    </p>
                    <button
                      :if={@selected_monitor.facts != []}
                      type="button"
                      phx-click="toggle_source_mapping_json"
                      class="text-xs text-text-muted hover:text-text"
                    >
                      {if @source_mapping_json_view, do: "Edit as form", else: "View as JSON"}
                    </button>
                  </div>
                  <p :if={@selected_monitor.facts == []} class="text-sm text-text-muted">
                    Define facts first (Facts tab) to configure field mappings.
                  </p>
                  <div :if={!@source_mapping_json_view && @selected_monitor.facts != []} class="space-y-2">
                    <div
                      :for={{key, name, path} <- @source_mapping_rows}
                      class="flex items-center gap-3"
                    >
                      <label class="w-40 shrink-0 text-sm text-text-muted">{name}</label>
                      <input
                        type="text"
                        value={path}
                        placeholder={mapping_placeholder(@source_adapter_type)}
                        phx-blur="update_source_mapping"
                        phx-value-key={key}
                        class="flex-1 rounded-lg border border-border bg-surface px-3 py-1.5 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                      />
                      <span :if={path == ""} class="shrink-0 text-warning" title="Not mapped">
                        <.icon name="hero-exclamation-triangle" class="size-4" />
                      </span>
                    </div>
                  </div>
                  <pre :if={@source_mapping_json_view && @selected_monitor.facts != []} class="overflow-auto rounded-lg border border-border bg-surface-raised p-3 font-mono text-xs text-text">{Jason.encode!(mappings_from_rows(@source_mapping_rows), pretty: true)}</pre>
                </div>

                <div class="flex items-center gap-3 pt-1">
                  <.button type="submit" variant="primary" size="sm">Save</.button>
                  <.button type="button" phx-click="cancel_source" variant="ghost" size="sm">Cancel</.button>
                </div>
              </.form>
            </div>

            <div
              :if={sources(@selected_monitor) == [] && @source_form_state == nil}
              class="py-4 text-sm text-text-muted"
            >
              No sources yet.
            </div>

            <.list
              :if={sources(@selected_monitor) != []}
              id={"sources-#{@selected_monitor.id}"}
              rows={sources(@selected_monitor)}
              row_id={& &1.id}
              editing_id={editing_id(@source_form_state)}
              sortable
              on_move="move_source"
            >
              <:row :let={source}>
                <p class="text-sm font-medium text-text">{source.name}</p>
                <p class="mt-0.5 text-xs text-text-muted">{source_adapter_label(source)}</p>
                <p :if={source.url && source.url != ""} class="mt-0.5 truncate font-mono text-xs text-text-muted">
                  {source.url}
                </p>
                <p :if={source.mappings && map_size(source.mappings) > 0} class="mt-0.5 text-xs text-text-muted">
                  {map_size(source.mappings)} fact(s) mapped
                </p>
              </:row>
              <:action :let={source}>
                <.button
                  :if={@source_form_state != {:edit, source.id}}
                  phx-click="edit_source"
                  phx-value-id={source.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Edit"
                >
                  <.icon name="hero-pencil" class="size-4" />
                </.button>
                <.button
                  :if={@confirm_delete_source_id != source.id}
                  phx-click="confirm_delete_source"
                  phx-value-id={source.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Delete"
                >
                  <.icon name="hero-trash" class="size-4" />
                </.button>
                <span :if={@confirm_delete_source_id == source.id} class="flex items-center gap-1.5">
                  <span class="text-xs text-text-muted">Delete?</span>
                  <.button phx-click="delete_source" phx-value-id={source.id} size="sm" variant="danger-ghost">Yes</.button>
                  <.button phx-click="cancel_delete_source" size="sm" variant="ghost">No</.button>
                </span>
              </:action>
            </.list>
          </.panel>
        </div>

        <%!-- TAB: Target --%>
        <div :if={@active_tab == :target && @selected_monitor}>
          <.panel
            title="Targets"
            description="Targets are compared against sources fact by fact for every entity."
          >
            <:actions>
              <.button
                :if={@target_form_state == nil}
                phx-click="new_target"
                size="sm"
                variant="soft"
              >
                Add target
              </.button>
            </:actions>

            <div :if={@target_form_state != nil} class={[targets(@selected_monitor) != [] && "mb-5", "rounded-xl border border-border bg-surface-raised p-4"]}>
              <h3 class="mb-4 text-sm font-semibold text-text">
                {if @target_form_state == :new, do: "Add target", else: "Editing: #{@target_form[:name].value}"}
              </h3>

              <form phx-change="set_target_adapter" class="mb-4">
                <label class="mb-1 block text-sm font-medium text-text-muted">Adapter</label>
                <select
                  name="type"
                  class="block w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-text outline-none focus:border-primary"
                >
                  <option
                    :for={{label, value} <- source_adapter_options()}
                    value={value}
                    selected={@target_adapter_type == value}
                  >
                    {label}
                  </option>
                </select>
              </form>

              <.form
                for={@target_form}
                phx-change="validate_target"
                phx-submit="save_target"
                class="space-y-4"
              >
                <.input field={@target_form[:name]} label="Name" />

                <div :if={@target_adapter_type == "http_json_per_entity"}>
                  <.input
                    field={@target_form[:url]}
                    label="URL — use :ref as the entity reference placeholder"
                    placeholder="http://api.example.com/products/:ref"
                  />
                </div>

                <div :if={@target_adapter_type == "http_json_bulk"} class="space-y-3">
                  <.input field={@target_form[:url]} label="URL — returns all entities" placeholder="http://api.example.com/products" />
                  <.input field={@target_form[:array_path]} label="Path to entity array in response" placeholder="e.g. products, response.docs" />
                  <.input field={@target_form[:ref_field]} label="Reference field" placeholder="id" />
                  <.input field={@target_form[:scope_ref_field]} label="Match against scope field (optional)" placeholder="Leave blank to use scope's reference field" />
                </div>

                <div :if={@target_adapter_type == "http_html"}>
                  <.input
                    field={@target_form[:url]}
                    label="URL — use :ref as the entity reference placeholder"
                    placeholder="http://www.example.com/products/:ref"
                  />
                </div>

                <div :if={@target_adapter_type == "csv"} class="space-y-3">
                  <.input field={@target_form[:url]} label="File URL" placeholder="http://host/files/products.csv" />
                  <.input field={@target_form[:ref_field]} label="Reference column" placeholder="product_id" />
                  <.input field={@target_form[:scope_ref_field]} label="Match against scope field (optional)" placeholder="Leave blank to use scope's reference field" />
                </div>

                <div>
                  <div class="mb-3 flex items-center justify-between">
                    <p class="text-sm font-medium text-text">
                      Field mappings
                      <span class="ml-1 text-xs font-normal text-text-muted">
                        — where in the response each fact value is found
                      </span>
                    </p>
                    <button
                      :if={@selected_monitor.facts != []}
                      type="button"
                      phx-click="toggle_target_mapping_json"
                      class="text-xs text-text-muted hover:text-text"
                    >
                      {if @target_mapping_json_view, do: "Edit as form", else: "View as JSON"}
                    </button>
                  </div>
                  <p :if={@selected_monitor.facts == []} class="text-sm text-text-muted">
                    Define facts first (Facts tab) to configure field mappings.
                  </p>
                  <div :if={!@target_mapping_json_view && @selected_monitor.facts != []} class="space-y-2">
                    <div
                      :for={{key, name, path} <- @target_mapping_rows}
                      class="flex items-center gap-3"
                    >
                      <label class="w-40 shrink-0 text-sm text-text-muted">{name}</label>
                      <input
                        type="text"
                        value={path}
                        placeholder={mapping_placeholder(@target_adapter_type)}
                        phx-blur="update_target_mapping"
                        phx-value-key={key}
                        class="flex-1 rounded-lg border border-border bg-surface px-3 py-1.5 text-sm text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                      />
                      <span :if={path == ""} class="shrink-0 text-warning" title="Not mapped">
                        <.icon name="hero-exclamation-triangle" class="size-4" />
                      </span>
                    </div>
                  </div>
                  <pre :if={@target_mapping_json_view && @selected_monitor.facts != []} class="overflow-auto rounded-lg border border-border bg-surface-raised p-3 font-mono text-xs text-text">{Jason.encode!(mappings_from_rows(@target_mapping_rows), pretty: true)}</pre>
                </div>

                <div class="flex items-center gap-3 pt-1">
                  <.button type="submit" variant="primary" size="sm">Save</.button>
                  <.button type="button" phx-click="cancel_target" variant="ghost" size="sm">Cancel</.button>
                </div>
              </.form>

              <%!-- Fact profile — separate from the source form, below it --%>
              <div :if={@target_profile_rows != []} class="mt-5">
                <p class="mb-1 text-sm font-medium text-text">Fact profile</p>
                <p class="mb-3 text-xs text-text-muted">
                  Which facts this target is expected to carry and how to compare them.
                </p>
                <div class="rounded-lg border border-border divide-y divide-border">
                  <div
                    :for={{fact_id, _key, fact_name, expected, comparison_type} <- @target_profile_rows}
                    class="flex items-center gap-3 px-3 py-2"
                  >
                    <span class="flex-1 min-w-0 truncate text-sm text-text">{fact_name}</span>
                    <form
                      phx-change="update_target_profile"
                      id={"profile-#{fact_id}"}
                      class="flex items-center gap-2 shrink-0"
                    >
                      <input type="hidden" name="fact_id" value={fact_id} />
                      <select
                        name="expected"
                        class="rounded border border-border bg-surface px-2 py-1 text-xs text-text outline-none focus:border-primary"
                      >
                        <option value="required" selected={expected == :required}>Required</option>
                        <option value="optional" selected={expected == :optional}>Optional</option>
                        <option value="excluded" selected={expected == :excluded}>Not checked</option>
                      </select>
                      <select
                        :if={expected != :excluded}
                        name="comparison_type"
                        class="rounded border border-border bg-surface px-2 py-1 text-xs text-text outline-none focus:border-primary"
                      >
                        <option value="" selected={is_nil(comparison_type)}>Default</option>
                        <option value="text" selected={comparison_type == :text}>Text</option>
                        <option value="text_case_insensitive" selected={comparison_type == :text_case_insensitive}>Ignore case</option>
                        <option value="numeric" selected={comparison_type == :numeric}>Numeric</option>
                        <option value="date" selected={comparison_type == :date}>Date</option>
                      </select>
                    </form>
                  </div>
                </div>
              </div>
            </div>

            <div
              :if={targets(@selected_monitor) == [] && @target_form_state == nil}
              class="py-4 text-sm text-text-muted"
            >
              No targets yet.
            </div>

            <.list
              :if={targets(@selected_monitor) != []}
              id={"targets-#{@selected_monitor.id}"}
              rows={targets(@selected_monitor)}
              row_id={& &1.id}
              editing_id={editing_id(@target_form_state)}
              sortable
              on_move="move_target"
            >
              <:row :let={source}>
                <p class="text-sm font-medium text-text">{source.name}</p>
                <p class="mt-0.5 text-xs text-text-muted">{source_adapter_label(source)}</p>
                <p :if={source.url && source.url != ""} class="mt-0.5 truncate font-mono text-xs text-text-muted">
                  {source.url}
                </p>
              </:row>
              <:action :let={source}>
                <.button
                  :if={@target_form_state != {:edit, source.id}}
                  phx-click="edit_target"
                  phx-value-id={source.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Edit"
                >
                  <.icon name="hero-pencil" class="size-4" />
                </.button>
                <.button
                  :if={@confirm_delete_target_id != source.id}
                  phx-click="confirm_delete_target"
                  phx-value-id={source.id}
                  size="sm"
                  variant="ghost"
                  aria-label="Delete"
                >
                  <.icon name="hero-trash" class="size-4" />
                </.button>
                <span :if={@confirm_delete_target_id == source.id} class="flex items-center gap-1.5">
                  <span class="text-xs text-text-muted">Delete?</span>
                  <.button phx-click="delete_target" phx-value-id={source.id} size="sm" variant="danger-ghost">Yes</.button>
                  <.button phx-click="cancel_delete_target" size="sm" variant="ghost">No</.button>
                </span>
              </:action>
            </.list>
          </.panel>
        </div>

        <%!-- TAB: Schedule --%>
        <div :if={@active_tab == :schedule && @selected_monitor} class="space-y-4">
          <.panel title="Run schedule" description="When to automatically run this monitor.">
            <.form
              :if={@schedule_form}
              for={@schedule_form}
              phx-submit="save_schedule"
              class="space-y-4"
            >
              <.input
                field={@schedule_form[:cron_expression]}
                label="Cron expression"
                placeholder="e.g. 0 */4 * * * — every 4 hours, 0 8 * * * — daily at 8am UTC"
              />
              <.button type="submit" variant="primary" size="sm">Save schedule</.button>
            </.form>
          </.panel>

          <.panel
            title="Maintenance windows"
            description="Scheduled runs are suppressed while a window is active."
          >
            <:actions>
              <.button
                :if={@window_form_state == nil}
                phx-click="new_window"
                size="sm"
                variant="soft"
              >
                Add window
              </.button>
            </:actions>

            <div
              :if={@selected_monitor.schedule_windows == [] && @window_form_state == nil}
              class="py-4 text-sm text-text-muted"
            >
              No maintenance windows configured.
            </div>

            <div
              :if={@selected_monitor.schedule_windows != []}
              class="divide-y divide-border"
            >
              <div
                :for={window <- @selected_monitor.schedule_windows}
                class="flex items-start justify-between gap-4 py-3 first:pt-0 last:pb-0"
              >
                <div>
                  <p class="text-sm font-medium text-text">{window.label || "Unlabeled"}</p>
                  <p class="mt-0.5 text-xs text-text-muted">{window.duration_seconds}s duration</p>
                  <p class="mt-0.5 font-mono text-xs text-text-muted">{window.rrule}</p>
                </div>
                <.button
                  phx-click="delete_window"
                  phx-value-id={window.id}
                  phx-confirm={"Delete window \"#{window.label || "this window"}\"?"}
                  size="sm"
                  variant="ghost"
                >
                  Delete
                </.button>
              </div>
            </div>

            <div
              :if={@window_form_state != nil}
              class="mt-4 rounded-xl border border-border bg-surface-raised p-4"
            >
              <h3 class="mb-4 text-sm font-semibold text-text">Add maintenance window</h3>
              <.form for={@window_form} phx-submit="save_window" class="space-y-3">
                <.input
                  field={@window_form[:label]}
                  label="Label (optional)"
                  placeholder="e.g. Weekend maintenance"
                />
                <div>
                  <label class="block text-sm font-medium text-text">
                    Recurrence (iCal RRULE)
                  </label>
                  <textarea
                    name="window[rrule]"
                    rows="3"
                    placeholder={"DTSTART:20260101T020000Z\nRRULE:FREQ=WEEKLY;BYDAY=SA"}
                    class="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-xs text-text placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-primary/50"
                  >{@window_form[:rrule].value}</textarea>
                  <p
                    :for={{msg, _opts} <- @window_form[:rrule].errors}
                    class="mt-1 text-xs text-danger"
                  >
                    {msg}
                  </p>
                </div>
                <.input
                  field={@window_form[:duration_seconds]}
                  type="number"
                  label="Duration (seconds)"
                  placeholder="3600"
                />
                <div class="flex items-center gap-3 pt-1">
                  <.button type="submit" variant="primary" size="sm">Save</.button>
                  <.button
                    type="button"
                    phx-click="cancel_window"
                    variant="ghost"
                    size="sm"
                  >
                    Cancel
                  </.button>
                </div>
              </.form>
            </div>
          </.panel>
        </div>
      </div>

      <.modal :if={@selected_monitor} id="archive-confirm-modal" size="sm">
        <:header>Archive monitor</:header>
        <p class="text-sm text-text-muted">
          <strong class="font-medium text-text">{@selected_monitor && @selected_monitor.name}</strong>
          will be removed from the active list. No new runs will be queued.
          You can restore it at any time from the monitors list.
        </p>
        <:footer>
          <.button type="button" phx-click={hide_modal("archive-confirm-modal")} size="sm">
            Cancel
          </.button>
          <.button
            phx-click="archive_monitor"
            phx-value-id={@selected_monitor && @selected_monitor.id}
            variant="ghost"
            size="sm"
          >
            Archive
          </.button>
        </:footer>
      </.modal>
    </.application_frame>
    """
  end

  defp load_monitor_lists(socket) do
    instance = socket.assigns.instance

    assign(socket,
      monitors: Monitors.list_monitors(instance),
      archived_monitors: Monitors.list_archived_monitors(instance)
    )
  end

  # -- Private: tab initialization --

  defp initialize_tab(socket, :scope) do
    if socket.assigns.scope_form == nil and socket.assigns.selected_monitor do
      monitor = socket.assigns.selected_monitor
      scope = scope_source(monitor)
      adapter = if scope, do: adapter_type_from_scope(scope), else: "http_json"
      form = if scope, do: source_form_from(scope), else: new_scope_form()

      assign(socket,
        scope_form: form,
        scope_adapter_type: adapter,
        scope_editing: is_nil(scope)
      )
    else
      socket
    end
  end

  defp initialize_tab(socket, _tab), do: socket

  # -- Private: source/fact finders --

  defp scope_source(monitor), do: Enum.find(monitor.sources, &(&1.role == :scope))
  defp sources(monitor), do: Enum.filter(monitor.sources, &(&1.role == :source))
  defp targets(monitor), do: Enum.filter(monitor.sources, &(&1.role == :target))

  defp editing_id({:edit, id}), do: id
  defp editing_id(_), do: nil

  # -- Private: tab completion indicators --

  defp tab_complete?(monitor, :scope), do: scope_source(monitor) != nil
  defp tab_complete?(monitor, :facts), do: monitor.facts != []
  defp tab_complete?(monitor, :source), do: sources(monitor) != []
  defp tab_complete?(monitor, :target), do: targets(monitor) != []

  defp tab_complete?(monitor, :schedule),
    do: not is_nil(monitor.cron_expression) and monitor.cron_expression != ""

  defp tab_complete?(_monitor, _tab), do: false

  # -- Private: adapter helpers --

  defp adapter_type_from(%{format: :json, fetch_strategy: :fetch_entity}), do: "http_json_per_entity"
  defp adapter_type_from(%{format: :json, fetch_strategy: :fetch_all_entities}), do: "http_json_bulk"
  defp adapter_type_from(%{format: :html}), do: "http_html"
  defp adapter_type_from(%{format: :manual}), do: "manual"
  defp adapter_type_from(%{format: :csv}), do: "csv"
  defp adapter_type_from(_), do: "http_json_per_entity"

  defp adapter_type_from_scope(%{format: :json}), do: "http_json"
  defp adapter_type_from_scope(%{format: :html}), do: "http_html"
  defp adapter_type_from_scope(%{format: :manual}), do: "manual"
  defp adapter_type_from_scope(%{format: :csv}), do: "csv"
  defp adapter_type_from_scope(_), do: "http_json"

  defp adapter_to_attrs("http_json_per_entity"), do: %{format: "json", fetch_strategy: "fetch_entity"}
  defp adapter_to_attrs("http_json_bulk"), do: %{format: "json", fetch_strategy: "fetch_all_entities"}
  defp adapter_to_attrs("http_html"), do: %{format: "html", fetch_strategy: "fetch_entity"}
  defp adapter_to_attrs("manual"), do: %{format: "manual", fetch_strategy: "fetch_all_entities"}
  defp adapter_to_attrs("csv"), do: %{format: "csv", fetch_strategy: "fetch_all_entities"}
  defp adapter_to_attrs("http_json"), do: %{format: "json", fetch_strategy: "fetch_all_entities"}
  defp adapter_to_attrs(_), do: %{format: "json", fetch_strategy: "fetch_entity"}

  defp scope_adapter_options do
    [
      {"HTTP JSON", "http_json"},
      {"HTTP HTML", "http_html"},
      {"Manual list", "manual"},
      {"CSV file", "csv"}
    ]
  end

  defp source_adapter_options do
    [
      {"HTTP JSON (per entity)", "http_json_per_entity"},
      {"HTTP JSON (all at once)", "http_json_bulk"},
      {"HTTP HTML", "http_html"},
      {"CSV file", "csv"}
    ]
  end

  # -- Private: display helpers --

  defp scope_adapter_label(%{format: :json}), do: "HTTP JSON"
  defp scope_adapter_label(%{format: :html}), do: "HTTP HTML"
  defp scope_adapter_label(%{format: :manual}), do: "Manual list"
  defp scope_adapter_label(%{format: :csv}), do: "CSV file"
  defp scope_adapter_label(_), do: "Unknown"

  defp source_adapter_label(%{format: :json, fetch_strategy: :fetch_entity}),
    do: "HTTP JSON (per entity)"

  defp source_adapter_label(%{format: :json, fetch_strategy: :fetch_all_entities}),
    do: "HTTP JSON (all at once)"

  defp source_adapter_label(%{format: :html}), do: "HTTP HTML"
  defp source_adapter_label(%{format: :csv}), do: "CSV file"
  defp source_adapter_label(_), do: "HTTP JSON (per entity)"

  defp comparison_type_label(:text), do: "text"
  defp comparison_type_label(:text_case_insensitive), do: "text (ignore case)"
  defp comparison_type_label(:numeric), do: "numeric"
  defp comparison_type_label(:date), do: "date"
  defp comparison_type_label(_), do: "text"

  defp mapping_placeholder("http_html"), do: "e.g. h1.product-name or [data-field=title]"
  defp mapping_placeholder("csv"), do: "e.g. ProductName (column header)"
  defp mapping_placeholder(_), do: "e.g. data.name or fields.Title.value"

  defp tags_from_monitor(monitor) do
    (monitor.entity_type || "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  # -- Private: mapping rows --

  defp build_mapping_rows(facts, mappings) do
    Enum.map(facts, fn fact ->
      {fact.key, fact.name, mappings[fact.key] || ""}
    end)
  end

  defp mappings_from_rows(rows) do
    Enum.reduce(rows, %{}, fn {key, _name, path}, acc ->
      if path != "", do: Map.put(acc, key, path), else: acc
    end)
  end

  defp build_target_profile_rows(facts, existing_profiles) do
    profiles_by_fact_id = Map.new(existing_profiles, &{&1.fact_id, &1})

    Enum.map(facts, fn fact ->
      profile = Map.get(profiles_by_fact_id, fact.id)
      expected = (profile && profile.expected) || :required
      comparison_type = profile && profile.comparison_type
      {fact.id, fact.key, fact.name, expected, comparison_type}
    end)
  end

  # -- Private: form helpers --

  defp slugify(name) do
    name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "_") |> String.trim("_")
  end

  defp new_monitor_form do
    to_form(Monitor.changeset(%Monitor{}, %{status: :active}), as: :monitor)
  end

  defp monitor_form_from(monitor) do
    to_form(Monitor.changeset(monitor, %{}), as: :monitor)
  end

  defp schedule_form_from(monitor) do
    to_form(Monitor.changeset(monitor, %{}), as: :monitor)
  end

  defp new_scope_form do
    to_form(
      Source.changeset(%Source{}, %{
        format: :json,
        fetch_strategy: :fetch_all_entities,
        role: :scope,
        mappings: %{},
        ref_field: "id"
      }),
      as: :source
    )
  end

  defp source_form_from(source) do
    to_form(Source.changeset(source, %{}), as: :source)
  end

  defp new_data_source_form do
    to_form(
      Source.changeset(%Source{}, %{
        format: :json,
        fetch_strategy: :fetch_entity,
        mappings: %{}
      }),
      as: :source
    )
  end

  defp new_fact_form do
    to_form(Fact.changeset(%Fact{}, %{comparison_type: :text}), as: :fact)
  end

  defp fact_form_from(fact) do
    to_form(Fact.changeset(fact, %{}), as: :fact)
  end

  defp new_window_form do
    to_form(ScheduleWindow.changeset(%ScheduleWindow{}, %{}), as: :window)
  end
end
