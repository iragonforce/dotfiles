local M = {}

local symbols = {
  "defun", "defmacro", "defgeneric", "defmethod", "defclass", "deftype",
  "defstruct", "defvar", "defparameter", "defconstant", "defpackage",
  "in-package", "lambda", "function", "quote", "if", "cond", "case",
  "typecase", "when", "unless", "and", "or", "not", "progn", "prog1",
  "prog2", "let", "let*", "flet", "labels", "macrolet", "symbol-macrolet",
  "block", "return-from", "catch", "throw", "unwind-protect", "handler-case",
  "handler-bind", "restart-case", "restart-bind", "ignore-errors", "assert",
  "check-type", "declare", "the", "values", "multiple-value-bind",
  "multiple-value-call", "multiple-value-prog1", "multiple-value-setq",
  "destructuring-bind", "with-slots", "with-accessors", "with-open-file",
  "with-open-stream", "with-output-to-string", "with-input-from-string",
  "with-standard-io-syntax", "with-hash-table-iterator", "do", "do*", "dolist",
  "dotimes", "do-symbols", "do-external-symbols", "do-all-symbols", "loop",
  "mapcar", "mapc", "mapcan", "maplist", "mapl", "mapcon", "map-into",
  "reduce", "remove", "delete", "remove-if", "delete-if", "remove-if-not",
  "delete-if-not", "remove-duplicates", "delete-duplicates", "find", "find-if",
  "find-if-not", "position", "position-if", "count", "count-if", "sort",
  "stable-sort", "merge", "concatenate", "coerce", "typep", "subtypep",
  "eq", "eql", "equal", "equalp", "atom", "consp", "listp", "null",
  "keywordp", "symbolp", "numberp", "integerp", "floatp", "rationalp",
  "complexp", "stringp", "characterp", "vectorp", "arrayp", "functionp",
  "hash-table-p", "streamp", "packagep", "classp", "make-instance", "slot-value",
  "slot-boundp", "slot-makunbound", "call-next-method", "next-method-p", "funcall",
  "apply", "eval", "compile", "load", "require", "provide", "format", "print",
  "prin1", "princ", "terpri", "read", "read-line", "parse-integer", "write",
  "write-line", "open", "close", "make-array", "aref", "svref", "row-major-aref",
  "fill", "replace", "copy-seq", "subseq", "elt", "nth", "first", "second",
  "third", "rest", "last", "butlast", "append", "nconc", "list", "list*",
  "cons", "adjoin", "push", "pushnew", "pop", "getf", "get", "remf", "assoc",
  "rassoc", "acons", "pairlis", "gethash", "remhash", "maphash", "make-hash-table",
  "+", "-", "*", "/", "1+", "1-", "incf", "decf", "mod", "rem", "abs", "min",
  "max", "floor", "ceiling", "truncate", "round", "sqrt", "expt", "random",
  "zerop", "plusp", "minusp", "evenp", "oddp", "zerop", "string=", "string-equal",
  "string<", "string-upcase", "string-downcase", "string-trim", "intern", "symbol-name",
  "symbol-package", "make-symbol", "gensym", "export", "import", "use-package",
  "find-package", "make-package", "delete-package", "asdf:load-system", "uiop:run-program",
}

local special_forms = {}

for _, symbol in ipairs(symbols) do
  special_forms[symbol] = false
end

for _, symbol in ipairs({
  "defun", "defmacro", "defgeneric", "defmethod", "defclass", "deftype", "defstruct",
  "defvar", "defparameter", "defconstant", "defpackage", "in-package", "lambda", "if",
  "cond", "case", "typecase", "when", "unless", "and", "or", "progn", "let", "let*",
  "flet", "labels", "macrolet", "block", "catch", "throw", "unwind-protect", "do", "do*",
  "dolist", "dotimes", "loop",
}) do
  special_forms[symbol] = true
end

local signatures = {
  defun = "(defun name (parameters) &body body)",
  defmacro = "(defmacro name (parameters) &body body)",
  defmethod = "(defmethod name (parameters) &body body)",
  defclass = "(defclass name (superclasses) (slots) &rest options)",
  defstruct = "(defstruct name &rest slot-specifications)",
  let = "(let ((variable value)*) &body body)",
  ["let*"] = "(let* ((variable value)*) &body body)",
  lambda = "(lambda (parameters) &body body)",
  ["if"] = "(if test then &optional else)",
  cond = "(cond &rest clauses)",
  when = "(when test &body body)",
  unless = "(unless test &body body)",
  format = "(format destination control-string &rest arguments)",
  mapcar = "(mapcar function list &rest more-lists)",
  reduce = "(reduce function sequence &key key from-end start end initial-value)",
  funcall = "(funcall function &rest arguments)",
  apply = "(apply function &rest args)",
  make_instance = "(make-instance class &rest initargs)",
  ["make-instance"] = "(make-instance class &rest initargs)",
  gethash = "(gethash key hash-table &optional default)",
  setf = "(setf place new-value &rest more-places-and-values)",
  load = "(load filespec &key verbose print if-does-not-exist external-format)",
  open = "(open filespec &key direction element-type if-exists if-does-not-exist)",
}

M.signature = function(symbol)
  symbol = symbol:gsub("^.*:", ""):lower()
  return signatures[symbol]
end

M.get_keyword_pattern = function()
  return [[\%(\k\|[-!?\*+/<>=:]\)\+]]
end

M.is_available = function()
  return vim.bo.filetype == "lisp"
end

M.complete = function(_, params, callback)
  local prefix = params.context.cursor_before_line:match("([%w_?!*+/<>=:%-]+)$") or ""
  local lower_prefix = prefix:lower()
  local kind = require("cmp.types").lsp.CompletionItemKind
  local items = {}

  for _, symbol in ipairs(symbols) do
    if lower_prefix == "" or symbol:sub(1, #lower_prefix):lower() == lower_prefix then
      table.insert(items, {
        label = symbol,
        kind = special_forms[symbol] and kind.Keyword or kind.Function,
        detail = "Common Lisp",
      })
    end
  end

  callback({ items = items, isIncomplete = false })
end

return M
