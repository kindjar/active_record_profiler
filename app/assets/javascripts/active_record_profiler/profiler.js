var ActiveRecordProfiler = (function (my_module) {
  my_module = my_module || {};

  var SOURCE_ROOT_KEY = "db_prof_source_root";
  var SOURCE_EDITOR_KEY = "db_prof_source_editor";
  var profilerSourceRootField, sourceEditorSelect, railsRoot, editorOptions, 
      linkFormatters = {};

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

  my_module.clearLinkFormatters = function () {
    $.each(linkFormatters, function (editorName, formatter) {
      if (editorOptions[editorName]) {
        editorOptions[editorName].remove();
      }
    });
    editorOptions = null;
    linkFormatters = {};
  };

  my_module.registerLinkFormatter = function (name, formatter) {
    if (!editorOptions) {
      editorOptions = {};
      sourceEditorSelect.find('option').each(function (index, el) {
        jqElement = $(el);
        editorOptions[jqElement.text()] = jqElement;
      });
    }

    linkFormatters[name] = formatter;
    if (!editorOptions[name]) {
      var newOption = $('<option>').text(name);
      editorOptions[name] = newOption;
      sourceEditorSelect.append(newOption);
      if (name === getSourceEditor()) {
        sourceEditorSelect.val(name);
      }
    } // else we already have an option and are just replacing the formatter
  };

  my_module.showSourceFile = function (file, line) {
    var root = profilerSourceRootField.val();
    var editor = sourceEditorSelect.val();
    if (root == "") { root = railsRoot; }

    if (!editor) {
      console.log("Cannot link to source code: no editor specified.");
      return;
    }
    var linkFormatter = linkFormatters[editor];
    if (!linkFormatter) {
      console.log("Cannot link to source code: no link formatter for editor '" + editor + "'.");
      return;
    }
    var link = linkFormatter(root + "/" + file, line, editor);
    if (!link) {
      console.log("Cannot link to source code: link formatter returned undefined.");
      return;
    }

    // Send browser to editor link
    window.location = link;
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

    // Install console.log dummy function if it doesn't exist, so we can log
    // without fuss.
    if (typeof window.console == 'undefined') { 
      window.console = {log: function (msg) {} }; 
    }

    // Add known editors/link formatters
    ActiveRecordProfiler.registerLinkFormatter('Sublime Text', function(file, line) {
      return "subl://open/?url=file://" + file + "&line=" + line;
    });
    ActiveRecordProfiler.registerLinkFormatter('TextMate', function(file, line) {
      return "txmt://open/?url=file://" + file + "&line=" + line;
    });
  });

  return my_module;
}(ActiveRecordProfiler));
