import { Controller } from "@hotwired/stimulus";

// Botão "Imprimir": data-controller="print" + data-action="click->print#print"
export default class extends Controller {
  print(event) {
    event.preventDefault();
    window.print();
  }
}
