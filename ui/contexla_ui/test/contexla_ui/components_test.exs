defmodule ContexlaUI.ComponentsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  use ContexlaUI, :html

  test "shared controls retain the design-system classes" do
    html = render_component(&showcase/1, %{})

    assert html =~ "btn btn-primary btn-sm"
    assert html =~ "rounded-lg border border-border bg-surface"
    assert html =~ "bg-primary-subtle text-primary"
  end

  test "toast is a viewport-level lower-corner overlay" do
    html =
      render_component(&ContexlaUI.Components.UI.Toast.toast/1, %{flash: %{"info" => "Saved"}})

    assert html =~ "fixed bottom-4"
    assert html =~ "inset-inline-end: 1rem"
  end

  test "data-heavy components are responsive by default" do
    html = render_component(&responsive_showcase/1, %{})

    assert html =~ "overflow-x-auto"
    assert html =~ ~s(scope="col")
    assert html =~ "max-h-[calc(100dvh-2rem)]"
    assert html =~ "overflow-y-auto"
  end

  test "icon picker preserves the Application default and offers shared icons" do
    html =
      render_component(&ContexlaUI.Components.UI.IconPicker.icon_picker/1, %{
        id: "instance-icon",
        name: "instance[icon]",
        value: nil,
        default_icon: "hero-beaker"
      })

    assert html =~ "Application default"
    assert html =~ ~s(value="hero-rocket-launch")
    assert html =~ ~s(name="instance[icon]")
  end

  test "Application frame keeps header, navigation, and content in the shared hierarchy" do
    html = render_component(&application_frame_showcase/1, %{})

    assert html =~ ~s(id="reference-application-header")
    assert html =~ "application-surface"
    assert html =~ "Section navigation"
    assert html =~ "Reference content"
    assert html =~ "border-b border-border bg-surface px-4 py-2"
  end

  test "surface patterns provide sectioned forms and responsive list detail" do
    html = render_component(&pattern_showcase/1, %{})

    assert html =~ "Identity"
    assert html =~ "border-t border-border pt-5"
    assert html =~ "lg:grid-cols-[minmax(16rem,0.8fr)_minmax(0,1.4fr)]"
    assert html =~ ~s(aria-label="Records")
    assert html =~ ~s(aria-label="Record details")
  end

  defp showcase(assigns) do
    ~H"""
    <.button variant="primary" size="sm">Run assessment</.button>
    <.input name="decision" value="" label="Decision" />
    <.header id="assessment-header" icon="hero-clipboard-document-check">
      Assessment
    </.header>
    """
  end

  defp responsive_showcase(assigns) do
    ~H"""
    <.tabs id="sections">
      <:tab label="Inventory" icon="hero-list-bullet" navigate="/inventory" selected />
    </.tabs>
    <.table id="resources" rows={[%{name: "Drupal"}]}>
      <:col :let={row} label="Name">{row.name}</:col>
    </.table>
    <.modal id="details">
      <p>Details</p>
    </.modal>
    """
  end

  defp application_frame_showcase(assigns) do
    ~H"""
    <.application_frame
      id="reference-application-header"
      icon="hero-beaker"
      title="Reference Application"
      subtitle="Configured Instance"
    >
      <:navigation>
        <.tabs id="reference-navigation">
          <:tab label="Overview" icon="hero-home" navigate="/" selected />
        </.tabs>
      </:navigation>
      <p>Reference content</p>
    </.application_frame>
    """
  end

  defp pattern_showcase(assigns) do
    ~H"""
    <.form_layout>
      <.form_section title="Identity">
        <p>Fields</p>
      </.form_section>
      <:actions><.button>Save</.button></:actions>
    </.form_layout>
    <.list_detail list_label="Records" detail_label="Record details">
      <:list>
        <p>List</p>
      </:list>
      <:detail>
        <p>Detail</p>
      </:detail>
    </.list_detail>
    """
  end
end
