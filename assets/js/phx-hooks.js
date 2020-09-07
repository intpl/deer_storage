export default {
  hookBurgerEvents: {
    mounted() {window.hook_navbar_burger()}
  },
  dropzoneHook: {
    mounted() {
      let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

      new Dropzone(this.el, {
        url: "/files/record/" + this.el.dataset.recordId,
        headers: {'x-csrf-token': csrfToken},
        success: function (file) {this.removeFile(file);}
      });
    }
  }
}
