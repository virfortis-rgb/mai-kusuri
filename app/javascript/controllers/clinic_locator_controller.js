import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status",
    "list",
    "query",
    "selectGroup",
    "inputGroup",
    "chatSelect",
    "manualInput",
    "chatId",
    "loader"
  ]

  checkInputType() {
    if (this.chatSelectTarget.value === "manual_input_mode") {
      this.switchToManualMode()
    }
  }

  switchToManualMode() {
    this.selectGroupTarget.classList.add("d-none")
    this.inputGroupTarget.classList.remove("d-none")
    this.manualInputTarget.focus()

  }

  resetToDropdown() {
    this.inputGroupTarget.classList.add("d-none")
    this.selectGroupTarget.classList.remove("d-none")
    this.manualInputTarget.value = ""
    this.chatSelectTarget.value = ""
  }

  search(event) {
    event.preventDefault()


    const query = this.hasQueryTarget ? this.queryTarget.value.trim() : ""


    if (!query) {
      this.setStatus("⚠️ Please enter a city or area first.")
      this.queryTarget?.focus()

      return
    }


    let params = { query }


    if (this.hasChatIdTarget && this.chatIdTarget.value) {
      params.type = this.chatIdTarget.value
    }


    const isManualMode = !this.inputGroupTarget.classList.contains("d-none")

    if (isManualMode) {
      const symptoms = this.manualInputTarget.value.trim()
      if (symptoms) params.symptoms = symptoms
    } else {
      const chatId = this.chatSelectTarget.value

      if (chatId && chatId !== "manual_input_mode") {
        params.chat_id = chatId
      }
    }


    this.showLoader()
    this.setStatus("Searching...")


    this.fetchClinics(params)
  }

  fetchClinics(paramsObj) {
    const params = new URLSearchParams(paramsObj)
    const url = `/clinics/search?${params.toString()}`

    fetch(url, { headers: { Accept: "application/json" } })
      .then((response) => {
        if (!response.ok) throw new Error("Network response was not ok")
        return response.json()
      })
      .then((data) => {

        this.hideLoader()

        if (data.error) {
          this.setStatus(`⚠️ ${data.error}`)
          return
        }

        if (!data.clinics || data.clinics.length === 0) {
          this.setStatus("No clinics found for that area.")
          this.listTarget.innerHTML = `
            <div class="col-12 text-center text-muted mt-4">
              <p>No results found. Try a broader city name.</p>
            </div>`
          return
        }

        this.setStatus(`✅ Found ${data.clinics.length} results.`)
        this.renderList(data.clinics)
      })
      .catch((error) => {
        console.error(error)
        this.hideLoader()
        this.setStatus("❌ Could not load clinics. Please try again.")
      })
  }

  renderList(clinics) {
    if (!this.hasListTarget) return

    const html = clinics.map(clinic => {

      const websiteButton = clinic.website_url
        ? `<a href="${clinic.website_url}" target="_blank" class="btn btn-sm btn-outline-secondary">Website</a>`
        : ''

      const ratingBadge = clinic.rating
        ? `<span class="badge bg-light text-dark border ms-2">⭐ ${clinic.rating}</span>`
        : ''

      return `
        <div class="col">
          <div class="card h-100 shadow-sm hover-shadow transition">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <h5 class="card-title text-primary mb-1">${clinic.name || "Clinic"}</h5>
                ${ratingBadge}
              </div>
              <p class="card-text small text-muted mb-3">
                <i class="bi bi-geo-alt-fill"></i> ${clinic.address || "Address unavailable"}
              </p>
              <div class="mt-auto">
                <a href="${clinic.maps_url}" target="_blank" rel="noopener" class="btn btn-sm btn-primary me-1">
                  View Map
                </a>
                ${websiteButton}
              </div>
            </div>
          </div>
        </div>
      `
    }).join("")

    this.listTarget.innerHTML = html
  }

// -----------------------------

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  showLoader() {
    if (this.hasListTarget) this.listTarget.innerHTML = "" // 清空列表
    if (this.hasLoaderTarget) this.loaderTarget.classList.remove("d-none")
  }

  hideLoader() {
    if (this.hasLoaderTarget) this.loaderTarget.classList.add("d-none")
  }
}
