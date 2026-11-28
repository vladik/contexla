// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/contexla"

const systemTheme = () => matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"

const setTheme = theme => {
  const selected = theme === "system" ? systemTheme() : theme
  document.documentElement.classList.toggle("dark", selected === "dark")
  document.documentElement.dataset.themeSource = theme === "system" ? "system" : "user"

  if (theme === "system") {
    localStorage.removeItem("phx:theme")
  } else {
    localStorage.setItem("phx:theme", theme)
  }

  document.querySelectorAll("[data-theme-choice]").forEach(button => {
    button.setAttribute("aria-pressed", String(button.dataset.themeChoice === selected))
  })
}

setTheme(localStorage.getItem("phx:theme") || "system")
window.addEventListener("storage", event => event.key === "phx:theme" && setTheme(event.newValue || "system"))
window.addEventListener("phx:set-theme", event => setTheme(event.target.dataset.phxTheme))
document.addEventListener("click", event => {
  const choice = event.target.closest("[data-theme-choice]")
  if (choice) {
    setTheme(choice.dataset.themeChoice)
    choice.closest("[data-theme-menu]")?.removeAttribute("open")
  }
})
matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
  if (document.documentElement.dataset.themeSource === "system") setTheme("system")
})

const installGlobalTooltips = () => {
  const tooltip = document.createElement("div")
  tooltip.id = "app-global-tooltip"
  tooltip.className = "app-global-tooltip"
  tooltip.setAttribute("role", "tooltip")
  tooltip.hidden = true
  document.body.appendChild(tooltip)
  let activeTrigger = null

  const hide = () => {
    activeTrigger?.removeAttribute("aria-describedby")
    activeTrigger = null
    tooltip.hidden = true
  }

  const show = trigger => {
    const text = trigger?.dataset.tooltip
    if (!text) return
    activeTrigger = trigger
    tooltip.textContent = text
    tooltip.hidden = false
    trigger.setAttribute("aria-describedby", tooltip.id)
    const triggerRect = trigger.getBoundingClientRect()
    const tooltipRect = tooltip.getBoundingClientRect()
    const gap = 8
    const edge = 8
    let left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2
    let top = triggerRect.top - tooltipRect.height - gap

    if (trigger.dataset.tooltipPosition === "side") {
      const sidebarRect = trigger.closest(".shell-sidebar")?.getBoundingClientRect() || triggerRect
      left = sidebarRect.right + gap
      top = triggerRect.top + (triggerRect.height - tooltipRect.height) / 2
    }

    tooltip.style.left = `${Math.min(Math.max(left, edge), window.innerWidth - tooltipRect.width - edge)}px`
    tooltip.style.top = `${Math.min(Math.max(top, edge), window.innerHeight - tooltipRect.height - edge)}px`
  }

  document.addEventListener("pointerover", event => {
    const trigger = event.target instanceof Element ? event.target.closest("[data-tooltip]") : null
    if (trigger && !trigger.contains(event.relatedTarget)) show(trigger)
  })
  document.addEventListener("pointerout", event => {
    if (activeTrigger && !activeTrigger.contains(event.relatedTarget)) hide()
  })
  document.addEventListener("focusin", event => {
    const trigger = event.target instanceof Element ? event.target.closest("[data-tooltip]") : null
    if (trigger) show(trigger)
  })
  document.addEventListener("focusout", hide)
  document.addEventListener("keydown", event => event.key === "Escape" && hide())
  document.addEventListener("scroll", hide, true)
  window.addEventListener("resize", hide)
}

const installSidebarCollapse = () => {
  const sidebar = document.querySelector("[data-sidebar-root]")
  const trigger = sidebar?.querySelector("[data-sidebar-collapse]")
  if (!sidebar || !trigger) return

  let collapsed = localStorage.getItem("sidebar-collapsed") === "true"
  const render = () => {
    document.documentElement.classList.toggle("sidebar-collapsed", collapsed)
    sidebar.classList.toggle("is-collapsed", collapsed)
    trigger.setAttribute("aria-expanded", String(!collapsed))
    const label = collapsed ? "Expand navigation" : "Collapse navigation"
    trigger.setAttribute("aria-label", label)
    trigger.dataset.tooltip = label
  }

  trigger.addEventListener("click", () => {
    collapsed = !collapsed
    localStorage.setItem("sidebar-collapsed", String(collapsed))
    render()
  })
  render()
}

const installMobileSidebar = () => {
  const sidebar = document.querySelector("[data-sidebar-root]")
  const backdrop = document.querySelector("#app-sidebar-backdrop")
  const trigger = document.querySelector("[data-mobile-sidebar-open]")
  const closeTriggers = document.querySelectorAll("[data-mobile-sidebar-close]")
  if (!sidebar || !backdrop || !trigger) return

  const close = () => {
    sidebar.classList.remove("is-mobile-open")
    backdrop.classList.add("hidden")
    trigger.setAttribute("aria-expanded", "false")
    document.documentElement.classList.remove("overflow-hidden")
  }

  const open = () => {
    sidebar.classList.add("is-mobile-open")
    backdrop.classList.remove("hidden")
    trigger.setAttribute("aria-expanded", "true")
    document.documentElement.classList.add("overflow-hidden")
  }

  trigger.addEventListener("click", open)
  closeTriggers.forEach(closeTrigger => closeTrigger.addEventListener("click", close))
  sidebar.addEventListener("click", event => {
    if (event.target.closest("a[href]")) close()
  })
  document.addEventListener("keydown", event => event.key === "Escape" && close())
}

const installIconPickers = () => {
  document.addEventListener("change", event => {
    const picker = event.target.closest?.("[data-icon-picker]")
    if (picker && event.target.matches("input[type='radio']")) picker.removeAttribute("open")
  })

  document.addEventListener("click", event => {
    document.querySelectorAll("[data-icon-picker][open]").forEach(picker => {
      if (!picker.contains(event.target)) picker.removeAttribute("open")
    })
  })
}

const installAgentWorkspace = () => {
  const workspace = document.querySelector("[data-agent-workspace]")
  const backdrop = document.querySelector("#agent-workspace-backdrop")
  const toggles = document.querySelectorAll("[data-agent-workspace-toggle]")
  const closeTriggers = document.querySelectorAll("[data-agent-workspace-close]")
  if (!workspace || !backdrop || toggles.length === 0) return

  let open = localStorage.getItem("agent-workspace-open") === "true"
  let returnFocus = null

  const render = () => {
    document.documentElement.classList.toggle("agent-workspace-open", open)
    workspace.setAttribute("aria-hidden", String(!open))
    workspace.inert = !open
    toggles.forEach(toggle => toggle.setAttribute("aria-expanded", String(open)))
    backdrop.classList.toggle("hidden", !open)
  }

  const setOpen = (nextOpen, trigger = null) => {
    open = nextOpen
    localStorage.setItem("agent-workspace-open", String(open))

    if (open) {
      returnFocus = trigger || document.activeElement
    }

    render()

    if (open && trigger) {
      workspace.querySelector("[data-agent-workspace-close]")?.focus()
    } else if (!open && returnFocus instanceof HTMLElement) {
      returnFocus.focus()
      returnFocus = null
    }
  }

  toggles.forEach(toggle => toggle.addEventListener("click", () => setOpen(!open, toggle)))
  closeTriggers.forEach(trigger => trigger.addEventListener("click", () => setOpen(false)))

  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && open) setOpen(false)
  })

  render()
}

installGlobalTooltips()
installSidebarCollapse()
installMobileSidebar()
installIconPickers()
installAgentWorkspace()

const Hooks = {
  ToastDismiss: {
    mounted() {
      this.dismiss = () => {
        this.el.classList.add("toast-animate-out")
        this.el.addEventListener("animationend", () => this.el.remove(), {once: true})
      }
      this.timeout = setTimeout(this.dismiss, 5000)
      this.el.addEventListener("click", event => {
        if (event.target.closest("[data-toast-dismiss]")) this.dismiss()
      })
    },
    destroyed() {
      if (this.timeout) clearTimeout(this.timeout)
    },
  },
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...Hooks, ...colocatedHooks},
})

window.addEventListener("phx:page-loading-start", () => document.documentElement.classList.add("page-loading"))
window.addEventListener("phx:page-loading-stop", () => document.documentElement.classList.remove("page-loading"))

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
