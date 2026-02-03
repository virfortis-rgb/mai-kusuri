import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "list", "query", "symptoms"]

  search(event) {
    event.preventDefault()

    this.clearList()
    const query = this.hasQueryTarget ? this.queryTarget.value.trim() : ""
    const symptoms = this.hasSymptomsTarget ? this.symptomsTarget.value.trim() : ""
    if (!query) {
      this.setStatus("Please enter a city or area first.")
      this.queryTarget?.focus()
      return
    }

    this.setStatus("Loading clinics...")
    this.fetchClinics(query, symptoms)
  }

  fetchClinics(query, symptoms) {
    const params = new URLSearchParams({ query })
    if (symptoms) params.set("symptoms", symptoms)
    const url = `/clinics/search?${params.toString()}`

    fetch(url, { headers: { Accept: "application/json" } })
      .then((response) => response.json())
      .then((data) => {
        if (!data || data.error) {
          this.setStatus(data?.error || "Could not load clinics.")
          return
        }

        if (!data.clinics || data.clinics.length === 0) {
          this.setStatus("No clinics found for that area.")
          return
        }

        this.setStatus("Showing clinics for that area.")
        this.renderList(data.clinics)
      })
      .catch(() => {
        this.setStatus("Could not load clinics.")
      })
  }

  renderList(clinics) {
    if (!this.hasListTarget) return
    this.listTarget.innerHTML = ""

    clinics.forEach((clinic) => {
      const li = document.createElement("li")
      li.className = "mb-2"

      const name = document.createElement("div")
      name.textContent = clinic.name || "Clinic"

      const link = document.createElement("a")
      link.href = clinic.website_url || clinic.maps_url
      link.target = "_blank"
      link.rel = "noopener"
      link.className = "fw-bold text-decoration-underline text-dark"
      link.textContent = clinic.website_url ? "Visit website" : "View on map"

      li.appendChild(name)
      li.appendChild(link)

      if (clinic.address) {
        const address = document.createElement("div")
        address.className = "text-muted"
        address.textContent = clinic.address
        li.appendChild(address)
      }

      this.listTarget.appendChild(li)
    })
  }

  clearList() {
    if (this.hasListTarget) {
      this.listTarget.innerHTML = ""
    }
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
