import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "groupsStage",
    "shapesStage",
    "groupCard",
    "selection",
    "progressStep",
    "progressLabel",
    "continue",
    "status"
  ]

  static values = {
    groupsProgress: String,
    shapesProgress: String,
    completeMessage: String
  }

  connect() {
    this.showStage("groups")
    this.clearOutlineSelection()
  }

  chooseGroup(event) {
    this.groupCardTargets.forEach((card) => {
      const selected = card === event.currentTarget
      card.classList.toggle("is-selected", selected)
      card.setAttribute("aria-pressed", String(selected))
    })

    this.clearOutlineSelection()
    this.showStage("shapes")
  }

  returnToGroups() {
    this.clearOutlineSelection()
    this.showStage("groups")
  }

  chooseShape(event) {
    this.selectOutline(event.currentTarget)
  }

  chooseFallback(event) {
    this.selectOutline(event.currentTarget)
  }

  announceSelection() {
    if (this.continueTarget.disabled) return

    this.statusTarget.textContent = this.completeMessageValue
    this.statusTarget.hidden = false
  }

  selectOutline(selectedButton) {
    this.selectionTargets.forEach((button) => {
      const selected = button === selectedButton
      button.classList.toggle("is-selected", selected)
      button.setAttribute("aria-pressed", String(selected))
    })

    this.continueTarget.disabled = false
    this.continueTarget.removeAttribute("aria-disabled")
    this.statusTarget.hidden = true
  }

  clearOutlineSelection() {
    this.selectionTargets.forEach((button) => {
      button.classList.remove("is-selected")
      button.setAttribute("aria-pressed", "false")
    })

    this.continueTarget.disabled = true
    this.continueTarget.setAttribute("aria-disabled", "true")
    this.statusTarget.hidden = true
  }

  showStage(stage) {
    const showingShapes = stage === "shapes"

    this.groupsStageTarget.hidden = showingShapes
    this.groupsStageTarget.classList.toggle("is-active", !showingShapes)
    this.shapesStageTarget.hidden = !showingShapes
    this.shapesStageTarget.classList.toggle("is-active", showingShapes)

    this.progressStepTargets.forEach((step, index) => {
      step.classList.toggle("is-active", index === 0 || showingShapes)
    })

    this.progressLabelTarget.textContent = showingShapes ? this.shapesProgressValue : this.groupsProgressValue
  }
}
