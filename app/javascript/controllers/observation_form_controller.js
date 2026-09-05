import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "partTab", "partPanel", "location", "save", "saveStatus", "dialog"]

  static values = {
    exitUrl: String,
    emptyMessage: String,
    certaintyMessage: String,
    readyMessage: String,
    locationLimitMessage: String
  }

  connect() {
    this.dirty = false
    this.beforeUnloadHandler = this.beforeUnload.bind(this)
    window.addEventListener("beforeunload", this.beforeUnloadHandler)
    this.renderState()
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  }

  choosePart(event) {
    const partKey = event.currentTarget.dataset.partKey
    this.partTabTargets.forEach((tab) => {
      const selected = tab.dataset.partKey === partKey
      tab.classList.toggle("is-active", selected)
      tab.setAttribute("aria-selected", String(selected))
    })
    this.partPanelTargets.forEach((panel) => { panel.hidden = panel.dataset.partKey !== partKey })
  }

  changed(event) {
    if (event.target.matches("[data-observation-form-target='location']")) {
      const selected = this.locationTargets.filter((input) => input.checked)
      if (selected.length > 2) {
        event.target.checked = false
        this.saveStatusTarget.textContent = this.locationLimitMessageValue
        return
      }
    }

    this.dirty = true
    this.renderState()
  }

  requestExit() {
    if (this.dirty) {
      this.dialogTarget.showModal()
    } else {
      window.location.assign(this.exitUrlValue)
    }
  }

  continueEditing() {
    this.dialogTarget.close()
  }

  discard() {
    this.dirty = false
    this.dialogTarget.close()
    window.location.assign(this.exitUrlValue)
  }

  submit() {
    this.dirty = false
  }

  beforeUnload(event) {
    if (!this.dirty) return

    event.preventDefault()
    event.returnValue = ""
  }

  renderState() {
    const states = this.partPanelTargets.map((panel) => this.partState(panel))
    const recorded = states.filter((state) => state.hasContent)
    const missingCertainty = recorded.some((state) => !state.hasCertainty)
    const canSave = recorded.length > 0 && !missingCertainty

    this.partTabTargets.forEach((tab, index) => tab.classList.toggle("is-set", states[index].hasContent))
    this.saveTarget.disabled = !canSave
    this.saveTarget.setAttribute("aria-disabled", String(!canSave))
    this.saveStatusTarget.textContent = recorded.length === 0
      ? this.emptyMessageValue
      : missingCertainty ? this.certaintyMessageValue : this.readyMessageValue
  }

  partState(panel) {
    const selectedValue = (field) => panel.querySelector(`input[name$='[${field}]']:checked`)?.value.trim()
    const description = panel.querySelector("textarea")?.value.trim()
    return {
      hasContent: Boolean(selectedValue("primary_color_key") || selectedValue("feature_key") || description),
      hasCertainty: Boolean(selectedValue("certainty_key"))
    }
  }
}
