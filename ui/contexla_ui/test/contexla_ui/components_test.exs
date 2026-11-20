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
end
