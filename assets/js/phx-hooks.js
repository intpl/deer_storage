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
  },
  hookCopyUrlToClipboard: {
    mounted() {
      this.el.addEventListener("click", () => {
        const target = document.getElementById('created_shared_record_generated_url');
        var range, select;

        if (document.createRange) {
          range = document.createRange();
          range.selectNode(target)
          select = window.getSelection();
          select.removeAllRanges();
          select.addRange(range);
          document.execCommand('copy');
          select.removeAllRanges();
        } else {
          range = document.body.createTextRange();
          range.moveToElementText(target);
          range.select();
          document.execCommand('copy');
        }
      })
    }
  },
  hookPreviewGestures: {
    mounted(){
      const xwiper = new window.Xwiper(this.el);

      xwiper.onSwipeRight(() => {this.pushEvent("previous_file_gesture", {})});
      xwiper.onSwipeLeft(() => {this.pushEvent("next_file_gesture", {})});

      $("#imagePreview").on("load", function() {
        $("#divLoading").remove();
      });
    }
  }
}
