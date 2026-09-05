import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "groupsStage", "outlinesStage", "groupCard", "groupOutlines", "selection",
    "progressStep", "progressLabel", "continue"
  ]

  static values = {
    editorUrl: String,
    groupsProgress: String,
    outlinesProgress: String
  }

  connect() {
    this.selectedOutline = null
  }

  chooseGroup(event) {
    const groupKey = event.currentTarget.dataset.groupKey
    this.groupCardTargets.forEach((card) => {
      const selected = card === event.currentTarget
      card.classList.toggle("is-selected", selected)
      card.setAttribute("aria-pressed", String(selected))
    })
    this.groupOutlinesTargets.forEach((group) => { group.hidden = group.dataset.groupKey !== groupKey })
    this.clearSelection()
    this.showOutlines()
  }

  returnToGroups() {
    this.clearSelection()
    this.groupsStageTarget.hidden = false
    this.outlinesStageTarget.hidden = true
    this.progressStepTargets[1].classList.remove("is-active")
    this.progressLabelTarget.textContent = this.groupsProgressValue
  }

  chooseOutline(event) {
    this.selectedOutline = event.currentTarget.dataset.outlineKey
    this.selectionTargets.forEach((button) => {
      const selected = button === event.currentTarget
      button.classList.toggle("is-selected", selected)
      button.setAttribute("aria-pressed", String(selected))
    })
    this.continueTarget.disabled = false
    this.continueTarget.removeAttribute("aria-disabled")
  }

  continue() {
    if (!this.selectedOutline) return

    const url = new URL(this.editorUrlValue, window.location.origin)
    url.searchParams.set("outline_key", this.selectedOutline)
    window.location.assign(url)
  }

  showOutlines() {
    this.groupsStageTarget.hidden = true
    this.outlinesStageTarget.hidden = false
    this.progressStepTargets[1].classList.add("is-active")
    this.progressLabelTarget.textContent = this.outlinesProgressValue
  }

  clearSelection() {
    this.selectedOutline = null
    this.selectionTargets.forEach((button) => {
      button.classList.remove("is-selected")
      button.setAttribute("aria-pressed", "false")
    })
    this.continueTarget.disabled = true
    this.continueTarget.setAttribute("aria-disabled", "true")
  }
}
