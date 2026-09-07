import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "frame"]
  static values = { url: String }

  connect() {
    this.inFlight = false
    this.pending = false
    this.debounceTimer = null
  }

  disconnect() {
    window.clearTimeout(this.debounceTimer)
  }

  schedule(event) {
    if (!event.target.name?.includes("observation[parts]")) return
    if (event.type === "input" && event.target.tagName !== "TEXTAREA") return

    if (event.target.tagName === "TEXTAREA") {
      window.clearTimeout(this.debounceTimer)
      this.debounceTimer = window.setTimeout(() => this.request(), 350)
    } else {
      this.request()
    }
  }

  request() {
    window.clearTimeout(this.debounceTimer)
    if (this.inFlight) {
      this.pending = true
      return
    }

    this.send()
  }

  async send() {
    this.inFlight = true
    this.pending = false

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        body: new FormData(this.formTarget),
        credentials: "same-origin",
        headers: {
          Accept: "text/html",
          "Turbo-Frame": this.frameTarget.id,
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
        }
      })

      if (response.redirected) {
        window.location.assign(response.url)
        return
      }
      if (!response.ok) throw new Error(`Preview request failed: ${response.status}`)

      const documentFragment = new DOMParser().parseFromString(await response.text(), "text/html")
      const incomingFrame = documentFragment.getElementById(this.frameTarget.id)
      if (!incomingFrame) throw new Error("Preview frame missing")

      this.frameTarget.innerHTML = incomingFrame.innerHTML
    } catch (_error) {
      const message = this.frameTarget.querySelector("[data-observation-preview-error]")
      if (message) message.hidden = false
    } finally {
      this.inFlight = false
      if (this.pending) this.send()
    }
  }
}
