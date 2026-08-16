import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status",
    "statusUnsaved",
    "title",
    "candidateList",
    "candidateInput",
    "candidateCount",
    "addButton",
    "candidateStaticHeading",
    "candidateToggle",
    "candidatePanel",
    "confirmSelected",
    "otherToggle",
    "otherControls",
    "otherInput",
    "confirmationControls",
    "confirmedControls",
    "confirmedDisplay",
    "confirmedEditor",
    "confirmedName",
    "editInput",
    "message",
    "saveBar",
    "dialog",
    "draftDialog",
    "revokeDialog",
    "revokeFinalName",
    "revokeRetainPanel",
    "revokeReplacePanel",
    "replacementList",
    "replaceAndRevoke"
  ]

  static values = {
    initialCandidates: Array,
    initialFinalName: String,
    defaultTitle: String,
    statusPending: String,
    statusCandidate: String,
    statusConfirmed: String,
    countTemplate: String,
    deleteLabelTemplate: String,
    selectLabelTemplate: String,
    limitMessage: String,
    emptyMessage: String,
    duplicateMessage: String,
    addedMessage: String,
    removedMessage: String,
    selectMessage: String,
    confirmedMessageTemplate: String,
    revokedMessage: String,
    revokedRetainedMessageTemplate: String,
    revokedReplacedMessageTemplate: String,
    savedMessage: String
  }

  connect() {
    this.savedCandidates = [...this.initialCandidatesValue]
    this.savedFinalName = this.initialFinalNameValue.trim()
    this.candidates = [...this.savedCandidates]
    this.selectedName = this.candidates[0] || null
    this.finalName = this.savedFinalName
    this.finalEditValue = this.finalName
    this.editingFinal = false
    this.otherExpanded = false
    this.candidatesExpanded = !this.finalName
    this.pendingUrl = null
    this.pendingDraftTarget = null
    this.replacementName = null
    this.dirty = false
    this.beforeUnloadHandler = this.beforeUnload.bind(this)
    window.addEventListener("beforeunload", this.beforeUnloadHandler)
    this.render()
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  }

  addCandidate() {
    const name = this.candidateInputTarget.value.trim()

    if (!name) {
      this.setMessage(this.emptyMessageValue)
      this.candidateInputTarget.focus()
      return
    }

    if (this.candidates.includes(name) || this.savedCandidates.includes(name)) {
      this.setMessage(this.duplicateMessageValue)
      this.candidateInputTarget.select()
      return
    }

    if (this.savedCandidates.length >= 3) {
      this.setMessage(this.limitMessageValue)
      return
    }

    this.candidates.push(name)
    this.savedCandidates.push(name)
    this.selectedName ||= name
    this.candidateInputTarget.value = ""
    this.setMessage(this.addedMessageValue)
    this.render()
    this.candidateInputTarget.focus()
  }

  selectCandidate(event) {
    this.selectedName = event.currentTarget.dataset.candidateName
    this.renderCandidateList()
    this.renderConfirmationControls()
  }

  toggleCandidates() {
    this.candidatesExpanded = !this.candidatesExpanded
    this.renderCandidateSection()
  }

  removeCandidate(event) {
    const name = event.currentTarget.dataset.candidateName
    this.candidates = this.candidates.filter((candidate) => candidate !== name)
    if (this.selectedName === name) this.selectedName = this.candidates[0] || null
    this.setMessage(this.removedMessageValue)
    this.render()
  }

  confirmSelected() {
    if (!this.selectedName) {
      this.setMessage(this.selectMessageValue)
      return
    }

    this.setFinalName(this.selectedName, { commit: true })
  }

  toggleOther() {
    this.otherExpanded = !this.otherExpanded
    this.renderOtherControls()
    if (this.otherExpanded) this.otherInputTarget.focus()
  }

  confirmOther() {
    const name = this.otherInputTarget.value.trim()
    if (!name) {
      this.setMessage(this.emptyMessageValue)
      this.otherInputTarget.focus()
      return
    }

    this.setFinalName(name, { commit: true })
  }

  beginFinalEdit() {
    this.editingFinal = true
    this.finalEditValue = this.finalName
    this.renderConfirmationControls()
    this.editInputTarget.value = this.finalEditValue
    this.editInputTarget.focus()
    this.editInputTarget.select()
  }

  updateFinalDraft(event) {
    this.finalEditValue = event.currentTarget.value
    this.renderIdentificationState()
    this.renderDirtyState()
  }

  revoke() {
    if (this.savedCandidates.includes(this.finalName)) {
      this.applyRevocation(this.revokedMessageValue)
      return
    }

    this.replacementName = null
    this.revokeFinalNameTargets.forEach((target) => { target.textContent = this.finalName })
    const candidatesAreFull = this.savedCandidates.length >= 3
    this.revokeRetainPanelTarget.hidden = candidatesAreFull
    this.revokeReplacePanelTarget.hidden = !candidatesAreFull
    if (candidatesAreFull) this.renderReplacementList()
    this.revokeDialogTarget.showModal()
  }

  retainAndRevoke() {
    const name = this.finalName
    if (!this.savedCandidates.includes(name)) this.savedCandidates.push(name)
    if (!this.candidates.includes(name)) this.candidates.push(name)
    this.selectedName ||= name
    this.revokeDialogTarget.close()
    this.applyRevocation(this.format(this.revokedRetainedMessageTemplateValue, { name }))
  }

  selectReplacement(event) {
    this.replacementName = event.currentTarget.value
    this.replaceAndRevokeTarget.disabled = false
    this.replaceAndRevokeTarget.setAttribute("aria-disabled", "false")
  }

  replaceAndRevoke() {
    if (!this.replacementName) return

    const replacedName = this.replacementName
    const retainedName = this.finalName
    const currentNames = new Set(this.candidates)
    currentNames.delete(replacedName)
    currentNames.add(retainedName)
    this.savedCandidates = this.savedCandidates.map((name) => name === replacedName ? retainedName : name)
    this.candidates = this.savedCandidates.filter((name) => currentNames.has(name))

    if (this.selectedName === replacedName) this.selectedName = retainedName
    this.revokeDialogTarget.close()
    this.applyRevocation(this.format(this.revokedReplacedMessageTemplateValue, {
      name: retainedName,
      replaced: replacedName
    }))
  }

  revokeWithoutRetaining() {
    this.revokeDialogTarget.close()
    this.applyRevocation(this.revokedMessageValue)
  }

  cancelRevoke() {
    this.revokeDialogTarget.close()
  }

  save() {
    this.commitChanges()
  }

  saveAndLeave() {
    if (!this.commitChanges()) return

    this.dialogTarget.close()
    this.navigateToPendingUrl()
  }

  continueEditing() {
    this.pendingUrl = null
    this.dialogTarget.close()
  }

  discardAndLeave() {
    this.dirty = false
    this.dialogTarget.close()
    this.navigateToPendingUrl()
  }

  continueDraft() {
    const target = this.pendingDraftTarget
    this.pendingUrl = null
    this.pendingDraftTarget = null
    this.draftDialogTarget.close()
    if (target === this.otherInputTarget) {
      this.otherExpanded = true
      this.renderOtherControls()
    } else if (target === this.candidateInputTarget) {
      this.candidatesExpanded = true
      this.renderCandidateSection()
    }
    if (target) target.focus()
  }

  discardDraftAndLeave() {
    this.clearDraftInputs()
    this.pendingDraftTarget = null
    this.draftDialogTarget.close()

    if (this.dirty) {
      this.dialogTarget.showModal()
    } else {
      this.navigateToPendingUrl()
    }
  }

  interceptNavigation(event) {
    const link = event.target.closest("a[href]")
    if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    const draftTarget = this.firstDraftInput()
    if (!draftTarget && !this.dirty) return

    event.preventDefault()
    this.pendingUrl = link.href
    if (draftTarget) {
      this.pendingDraftTarget = draftTarget
      this.draftDialogTarget.showModal()
    } else {
      this.dialogTarget.showModal()
    }
  }

  beforeUnload(event) {
    if (!this.dirty && !this.firstDraftInput()) return

    event.preventDefault()
    event.returnValue = ""
  }

  setFinalName(name, { commit = false } = {}) {
    this.finalName = name
    this.finalEditValue = name
    this.editingFinal = false
    this.otherExpanded = false
    this.candidatesExpanded = false
    this.otherInputTarget.value = ""
    if (commit) this.savedFinalName = name
    this.setMessage(this.format(this.confirmedMessageTemplateValue, { name }))
    this.render()
  }

  commitChanges() {
    if (this.editingFinal) {
      const name = this.finalEditValue.trim()
      if (!name) {
        this.setMessage(this.emptyMessageValue)
        if (this.dialogTarget.open) this.dialogTarget.close()
        this.editInputTarget.focus()
        return false
      }

      this.finalName = name
      this.finalEditValue = name
      this.editingFinal = false
    }

    this.savedCandidates = [...this.candidates]
    this.savedFinalName = this.finalName
    this.dirty = false
    this.setMessage(this.savedMessageValue)
    this.render()
    return true
  }

  navigateToPendingUrl() {
    const url = this.pendingUrl
    this.pendingUrl = null
    if (url) window.location.assign(url)
  }

  applyRevocation(message) {
    this.savedFinalName = ""
    this.finalName = ""
    this.finalEditValue = ""
    this.editingFinal = false
    this.otherExpanded = false
    this.candidatesExpanded = true
    this.setMessage(message)
    this.render()
  }

  renderReplacementList() {
    const options = this.savedCandidates.map((name) => {
      const label = document.createElement("label")
      label.className = "revoke-candidate-option"

      const input = document.createElement("input")
      input.type = "radio"
      input.name = "revoke-replacement"
      input.value = name
      input.dataset.action = "identification#selectReplacement"

      const text = document.createElement("span")
      text.textContent = name
      label.append(input, text)
      return label
    })

    this.replacementListTarget.replaceChildren(...options)
    this.replaceAndRevokeTarget.disabled = true
    this.replaceAndRevokeTarget.setAttribute("aria-disabled", "true")
  }

  firstDraftInput() {
    return [this.candidateInputTarget, this.otherInputTarget].find((target) => target.value.trim()) || null
  }

  clearDraftInputs() {
    this.candidateInputTarget.value = ""
    this.otherInputTarget.value = ""
  }

  render() {
    this.renderCandidateList()
    this.renderIdentificationState()
    this.renderConfirmationControls()
    this.renderCandidateSection()
    this.renderDirtyState()
  }

  renderCandidateList() {
    const rows = this.candidates.map((name) => {
      const row = document.createElement("div")
      row.className = `candidate-row${name === this.selectedName ? " is-selected" : ""}`
      row.dataset.candidateName = name

      const select = document.createElement("button")
      select.type = "button"
      select.className = "candidate-select"
      select.dataset.candidateName = name
      select.dataset.action = "identification#selectCandidate"
      select.setAttribute("aria-pressed", String(name === this.selectedName))
      select.setAttribute("aria-label", this.format(this.selectLabelTemplateValue, { name }))

      const label = document.createElement("span")
      label.textContent = name
      select.append(label)

      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "candidate-delete"
      remove.dataset.candidateName = name
      remove.dataset.action = "identification#removeCandidate"
      remove.setAttribute("aria-label", this.format(this.deleteLabelTemplateValue, { name }))
      remove.textContent = "×"

      row.append(select, remove)
      return row
    })

    this.candidateListTarget.replaceChildren(...rows)
    this.candidateCountTargets.forEach((target) => {
      target.textContent = this.format(this.countTemplateValue, { count: this.candidates.length })
    })

    const candidateLimitReached = this.savedCandidates.length >= 3
    this.addButtonTarget.disabled = candidateLimitReached
    this.addButtonTarget.setAttribute("aria-disabled", String(candidateLimitReached))
  }

  renderCandidateSection() {
    const confirmedMode = Boolean(this.finalName) || this.editingFinal
    if (!confirmedMode) this.candidatesExpanded = true

    this.candidateStaticHeadingTarget.hidden = confirmedMode
    this.candidateToggleTarget.hidden = !confirmedMode
    this.candidatePanelTarget.hidden = confirmedMode && !this.candidatesExpanded
    this.candidateToggleTarget.setAttribute("aria-expanded", String(this.candidatesExpanded))
  }

  renderIdentificationState() {
    const finalName = this.effectiveFinalName()
    const state = finalName ? "confirmed" : this.candidates.length ? "candidate" : "pending"
    const labels = {
      pending: this.statusPendingValue,
      candidate: this.statusCandidateValue,
      confirmed: this.statusConfirmedValue
    }

    this.statusTarget.textContent = labels[state]
    this.statusTarget.classList.remove("status-pill--pending", "status-pill--candidate", "status-pill--confirmed")
    this.statusTarget.classList.add(`status-pill--${state}`)
    this.titleTarget.textContent = finalName || this.defaultTitleValue
  }

  renderConfirmationControls() {
    const confirmedMode = Boolean(this.finalName) || this.editingFinal
    this.confirmationControlsTarget.hidden = confirmedMode
    this.confirmedControlsTarget.hidden = !confirmedMode
    this.confirmedDisplayTarget.hidden = !confirmedMode || this.editingFinal
    this.confirmedEditorTarget.hidden = !this.editingFinal
    this.confirmSelectedTarget.disabled = !this.selectedName
    this.confirmSelectedTarget.setAttribute("aria-disabled", String(!this.selectedName))
    this.renderOtherControls()

    if (confirmedMode && !this.editingFinal) this.confirmedNameTarget.textContent = this.finalName
  }

  renderOtherControls() {
    this.otherControlsTarget.hidden = !this.otherExpanded
    this.otherToggleTarget.setAttribute("aria-expanded", String(this.otherExpanded))
  }

  renderDirtyState() {
    this.dirty = this.hasChanges()
    this.saveBarTarget.hidden = !this.dirty
    this.statusUnsavedTarget.hidden = !this.dirty
  }

  hasChanges() {
    const candidatesChanged = JSON.stringify(this.candidates) !== JSON.stringify(this.savedCandidates)
    return candidatesChanged || this.effectiveFinalName() !== this.savedFinalName
  }

  effectiveFinalName() {
    return this.editingFinal ? this.finalEditValue.trim() : this.finalName
  }

  setMessage(message) {
    this.messageTarget.textContent = message
  }

  format(template, values) {
    return Object.entries(values).reduce((result, [key, value]) => result.replaceAll(`%{${key}}`, value), template)
  }
}
