import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-twitter-word"
export default class extends Controller {
  static targets = ["help"];
  clicked() {
    // TODO: Change this into a turbo thing, instead of stimulus
    var elm = document.createElement("input");
    elm.name = "user[twitter_word_list][]";
    elm.value = ""
    elm.placeholder = "#tw"
    elm.classList.add("input")
    elm.type = "text"
    elm.id = "user_twitter_word_list"
    var target = this.helpTarget
    target.parentNode.insertBefore(elm, target)
  }
}
