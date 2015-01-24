var ActiveRecordProfiler = (function (my_module) {
  my_module = my_module || {};

  var SOURCE_ROOT_KEY = "db_prof_source_root";
  var SOURCE_EDITOR_KEY = "db_prof_source_editor";
  var profilerSourceRootField, sourceEditorSelect, railsRoot;

  function supportsLocalStorage() {
    try {
      return (('localStorage' in window) && (window['localStorage'] !== null));
    } catch (e) {
      return false;
    }
  }

  function setDBProfSourceRoot(value) {
    if (supportsLocalStorage()) {
      if (!!value) {
        window.localStorage[SOURCE_ROOT_KEY] = value;
      } else {
        window.localStorage.removeItem(SOURCE_ROOT_KEY);
      } 
    }
  }

  function getDBProfSourceRoot() {
    var root = railsRoot;

    if (supportsLocalStorage()) {
      var localRoot = window.localStorage[SOURCE_ROOT_KEY];
      if (!!localRoot) {
        root = localRoot;
      }
    }
    return root;
  }

  function setSourceEditor(value) {
    if (supportsLocalStorage()) {
      if (!!value) {
        window.localStorage[SOURCE_EDITOR_KEY] = value;
      } else {
        window.localStorage.removeItem(SOURCE_EDITOR_KEY);
      } 
    }
  }

  function getSourceEditor() {
    if (supportsLocalStorage()) {
      return window.localStorage[SOURCE_EDITOR_KEY];
    } else {
      return undefined;
    }
  }

  my_module.formatLink = function (file, line, editor) {
    var link;

    switch (editor) {
      case "subl":
      case "txmt":
        link = editor + "://open/?url=file://" + file + "&line=" + line;
        break;
      default:
        // do nothing, return undefined link
    }

    return link;
  };

  my_module.showSourceFile = function (file, line) {
    var root = profilerSourceRootField.val();
    var editor = sourceEditorSelect.val();
    if (root == "") { root = railsRoot; }
    // window.location = "txmt://open/?url=file://" + root + "/" + file + "&line=" + line;
    var link = my_module.formatLink(root + "/" + file, line, editor);
    if (link) {
      window.location = link;
    }
  };

  $(function () {
    profilerSourceRootField = $('#source_root');
    railsRoot = profilerSourceRootField.val();

    profilerSourceRootField.val(getDBProfSourceRoot());
    profilerSourceRootField.change(function (e) {
      setDBProfSourceRoot($(this).val());
    });
    
    sourceEditorSelect = $('#source_editor');
    sourceEditorSelect.val(getSourceEditor());
    sourceEditorSelect.change(function (e) {
      setSourceEditor($(this).val());
    })

    $('.profiler-report').on('click', '.source-link', function (event) {
      var link = $(this);
      my_module.showSourceFile(link.data('file'), link.data('line'));
    });
  });

  return my_module;
}(ActiveRecordProfiler));
