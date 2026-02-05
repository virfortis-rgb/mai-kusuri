
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hideable", "content", "icon"]

  call(event) {
    event.preventDefault()

    this.hideableTarget.classList.toggle("collapsed")
    this.iconTarget.classList.toggle("active-toggle")


    if (this.hideableTarget.classList.contains("collapsed")) {
      this.contentTarget.classList.replace("col-md-10", "col-md-12")
    } else {
      this.contentTarget.classList.replace("col-md-12", "col-md-10")
    }
  }
}
