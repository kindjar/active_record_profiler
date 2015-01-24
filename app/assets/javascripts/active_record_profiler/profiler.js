var ActiveRecordProfiler = (function (my_module) {
  my_module = my_module || {};

  var SOURCE_ROOT_COOKIE_NAME = "db_prof_source_root";
  var profilerSourceRootField, railsRoot;

  function setDBProfSourceRoot(value) {
    var expireDate = new Date(); 
    var expireDays = 356;
    expireDate.setDate(expireDate.getDate() + expireDays);
    document.cookie = SOURCE_ROOT_COOKIE_NAME + "=" + escape(value) + 
        ";expires=" + expireDate.toGMTString();
  }

  function getDBProfSourceRoot() {
    var root = railsRoot;

    if (document.cookie.length>0) {
      // TODO: this is ugly and complicated and should be rewritten
      var cookieStart = document.cookie.indexOf(SOURCE_ROOT_COOKIE_NAME + "=");
      if (cookieStart != -1) {
        cookieStart = cookieStart + SOURCE_ROOT_COOKIE_NAME.length + 1;
        var cookieEnd = document.cookie.indexOf(";", cookieStart);
        if (cookieEnd == -1) { 
          cookieEnd = document.cookie.length; 
        }
        var cookieRoot = document.cookie.substring(cookieStart, cookieEnd);
        if (cookieRoot != "") {
          root = unescape(cookieRoot);
        }
      }
    }
    return root;
  }

  my_module.showSourceFile = function (file, line) {
    var root = profilerSourceRootField.val();
    if (root == "") { root = railsRoot; }
    window.location = "txmt://open/?url=file://" + root + "/" + file + "&line=" + line;
  };

  $(function () {
    profilerSourceRootField = $('#source_root');
    railsRoot = profilerSourceRootField.val();

    profilerSourceRootField.val(getDBProfSourceRoot());
    profilerSourceRootField.change(function(e){
      setDBProfSourceRoot($(this).val());
    });

    $('.profiler-report').on('click', '.source-link', function (event) {
      var link = $(this);
      my_module.showSourceFile(link.data('file'), link.data('line'));
    });
  });

  return my_module;
}(ActiveRecordProfiler));
