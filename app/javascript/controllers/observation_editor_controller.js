import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "partTab",
    "partTitle",
    "partStatus",
    "primaryChoice",
    "secondaryChoice",
    "featureChoice",
    "certaintyChoice",
    "note",
    "locationChoice",
    "behavior",
    "partGraphic",
    "partAccent",
    "summary",
    "save",
    "saveStatus",
    "dialog"
  ]

  static values = {
    outlineUrl: String,
    partTitleTemplate: String,
    partStatusNone: String,
    partStatusOneTemplate: String,
    partStatusManyTemplate: String,
    summaryEmpty: String,
    summaryItemTemplate: String,
    summaryPrimaryTemplate: String,
    summarySecondaryTemplate: String,
    summaryFeatureTemplate: String,
    summaryNoteTemplate: String,
    summaryCertaintyPending: String,
    saveEmpty: String,
    saveCertainty: String,
    saveReady: String,
    saveComplete: String,
    locationLimit: String
  }

  connect() {
    this.parts = Object.fromEntries(this.partTabTargets.map((tab) => [tab.dataset.partKey, this.emptyPart()]))
    this.currentPart = this.partTabTargets.find((tab) => tab.classList.contains("is-active"))?.dataset.partKey || this.partTabTargets[0].dataset.partKey
    this.selectedLocations = new Set()
    this.dirty = false
    this.saved = false
    this.beforeUnloadHandler = this.beforeUnload.bind(this)
    window.addEventListener("beforeunload", this.beforeUnloadHandler)
    this.render()
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  }

  choosePart(event) {
    this.currentPart = event.currentTarget.dataset.partKey
    this.renderPartPanel()
  }

  choosePrimary(event) {
    this.togglePartChoice("primary", event.currentTarget, this.primaryChoiceTargets)
  }

  chooseSecondary(event) {
    this.togglePartChoice("secondary", event.currentTarget, this.secondaryChoiceTargets)
  }

  chooseFeature(event) {
    this.togglePartChoice("feature", event.currentTarget, this.featureChoiceTargets)
  }

  chooseCertainty(event) {
    this.togglePartChoice("certainty", event.currentTarget, this.certaintyChoiceTargets)
  }

  updateNote() {
    this.currentState.note = this.noteTarget.value
    this.markDirty()
    this.renderDerivedState()
  }

  chooseLocation(event) {
    const button = event.currentTarget
    const key = button.dataset.optionKey

    if (this.selectedLocations.has(key)) {
      this.selectedLocations.delete(key)
    } else if (this.selectedLocations.size < 2) {
      this.selectedLocations.add(key)
    } else {
      this.saveStatusTarget.textContent = this.locationLimitValue
      return
    }

    this.markDirty()
    this.renderLocations()
    this.renderSaveState()
  }

  updateBehavior() {
    this.markDirty()
    this.renderSaveState()
  }

  requestExit() {
    if (this.dirty) {
      this.dialogTarget.showModal()
    } else {
      window.location.assign(this.outlineUrlValue)
    }
  }

  continueEditing() {
    this.dialogTarget.close()
  }

  discard() {
    this.dirty = false
    this.dialogTarget.close()
    window.location.assign(this.outlineUrlValue)
  }

  save() {
    if (this.saveTarget.disabled) return

    this.dirty = false
    this.saved = true
    this.saveStatusTarget.textContent = this.saveCompleteValue
  }

  beforeUnload(event) {
    if (!this.dirty) return

    event.preventDefault()
    event.returnValue = ""
  }

  emptyPart() {
    return { primary: null, secondary: null, feature: null, certainty: null, note: "" }
  }

  get currentState() {
    return this.parts[this.currentPart]
  }

  togglePartChoice(field, button, targets) {
    const selectedKey = this.currentState[field]?.key
    this.currentState[field] = selectedKey === button.dataset.optionKey ? null : this.optionFrom(button)
    this.markDirty()
    this.renderChoiceGroup(targets, this.currentState[field]?.key)
    this.renderDerivedState()
  }

  optionFrom(button) {
    return {
      key: button.dataset.optionKey,
      name: button.dataset.optionName,
      value: button.dataset.optionValue
    }
  }

  markDirty() {
    this.dirty = true
    this.saved = false
  }

  render() {
    this.renderPartPanel()
    this.renderLocations()
    this.renderDerivedState()
  }

  renderPartPanel() {
    const activeTab = this.partTabTargets.find((tab) => tab.dataset.partKey === this.currentPart)

    this.partTabTargets.forEach((tab) => {
      const active = tab === activeTab
      tab.classList.toggle("is-active", active)
      tab.setAttribute("aria-selected", String(active))
    })

    this.partTitleTarget.textContent = this.format(this.partTitleTemplateValue, { part: activeTab.dataset.partName })
    this.renderChoiceGroup(this.primaryChoiceTargets, this.currentState.primary?.key)
    this.renderChoiceGroup(this.secondaryChoiceTargets, this.currentState.secondary?.key)
    this.renderChoiceGroup(this.featureChoiceTargets, this.currentState.feature?.key)
    this.renderChoiceGroup(this.certaintyChoiceTargets, this.currentState.certainty?.key)
    this.noteTarget.value = this.currentState.note
  }

  renderChoiceGroup(targets, selectedKey) {
    targets.forEach((button) => {
      const selected = button.dataset.optionKey === selectedKey
      button.setAttribute("aria-pressed", String(selected))
      button.closest(".swatch-item")?.classList.toggle("is-selected", selected)
    })
  }

  renderLocations() {
    this.locationChoiceTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(this.selectedLocations.has(button.dataset.optionKey)))
    })
  }

  renderDerivedState() {
    this.renderPartTabs()
    this.renderPreview()
    this.renderSummary()
    this.renderSaveState()
  }

  renderPartTabs() {
    const recorded = this.recordedParts()

    this.partTabTargets.forEach((tab) => {
      tab.classList.toggle("is-set", this.partHasFeatures(this.parts[tab.dataset.partKey]))
    })

    if (recorded.length === 0) {
      this.partStatusTarget.textContent = this.partStatusNoneValue
    } else if (recorded.length === 1) {
      this.partStatusTarget.textContent = this.format(this.partStatusOneTemplateValue, { part: this.partName(recorded[0][0]) })
    } else {
      this.partStatusTarget.textContent = this.format(this.partStatusManyTemplateValue, { count: recorded.length })
    }
  }

  renderPreview() {
    this.partGraphicTargets.forEach((graphic) => {
      const state = this.parts[graphic.dataset.partKey]
      graphic.setAttribute("fill", state.primary?.value || graphic.dataset.defaultFill)
      graphic.classList.remove("feature-stripe", "feature-spots", "feature-patch")
      if (state.feature && state.feature.key !== "solid") graphic.classList.add(`feature-${state.feature.key}`)
    })

    this.partAccentTargets.forEach((accent) => {
      const secondary = this.parts[accent.dataset.partKey].secondary
      accent.hidden = !secondary
      if (secondary) accent.setAttribute("fill", secondary.value)
    })
  }

  renderSummary() {
    const items = this.recordedParts().map(([key, state]) => {
      const details = []
      if (state.primary) details.push(this.format(this.summaryPrimaryTemplateValue, { value: state.primary.name }))
      if (state.secondary) details.push(this.format(this.summarySecondaryTemplateValue, { value: state.secondary.name }))
      if (state.feature) details.push(this.format(this.summaryFeatureTemplateValue, { value: state.feature.name }))
      if (state.note.trim()) details.push(this.format(this.summaryNoteTemplateValue, { value: state.note.trim() }))

      return this.format(this.summaryItemTemplateValue, {
        part: this.partName(key),
        details: details.join("、"),
        certainty: state.certainty?.name || this.summaryCertaintyPendingValue
      })
    })

    this.summaryTarget.textContent = items.length ? items.join("\n") : this.summaryEmptyValue
  }

  renderSaveState() {
    const recorded = this.recordedParts()
    const missingCertainty = recorded.some(([, state]) => !state.certainty)
    const canSave = recorded.length > 0 && !missingCertainty

    this.saveTarget.disabled = !canSave
    if (canSave) {
      this.saveTarget.removeAttribute("aria-disabled")
    } else {
      this.saveTarget.setAttribute("aria-disabled", "true")
    }

    if (this.saved) return

    if (recorded.length === 0) {
      this.saveStatusTarget.textContent = this.saveEmptyValue
    } else if (missingCertainty) {
      this.saveStatusTarget.textContent = this.saveCertaintyValue
    } else {
      this.saveStatusTarget.textContent = this.saveReadyValue
    }
  }

  recordedParts() {
    return Object.entries(this.parts).filter(([, state]) => this.partHasFeatures(state))
  }

  partHasFeatures(state) {
    return Boolean(state.primary || state.secondary || state.feature || state.note.trim())
  }

  partName(key) {
    return this.partTabTargets.find((tab) => tab.dataset.partKey === key).dataset.partName
  }

  format(template, values) {
    return Object.entries(values).reduce((result, [key, value]) => result.replaceAll(`%{${key}}`, value), template)
  }
}
