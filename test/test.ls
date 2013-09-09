{eq, p, q} = require './_utils'
require! assert

code-func = '''
  function addTwo(x, z) {
    var y = 2;
    z();
    return y + x;
  }
'''

code-each = '
  _.each("hi", false);
'
code-each2 = '
  underscore.each(/re/gi, null);
'
code = "#code-func\n#code-each\n#code-each2"

ret =
  type: 'ReturnStatement'
  argument: p 'y + x'

suite 'misc' ->
  test 'no matches' ->
    eq [], 'ZZ++', code
    eq [], 'var y = 4', code
    eq [], '[2][0]', code

  test 'no special' ->
    eq 'y + x', 'y + x', code
    eq 'z()', 'z()', code

  test 'different ifs' ->
    code = '''
           if (x) {
             f(x);
           }
           '''
    eq code, 'if(x){f(x);}', code

  test 'normally unparsable JS' ->
    eq ret, 'return y + x', code

  test 'underscore identifier' ->
    eq code-each, '_.each("hi", false)', code

  test 'loc' ->
    bi =
      type: 'BinaryExpression'
      operator: '+'
      left:
        type: 'Identifier'
        name: 'y'
        loc:
          start:
            line: 4
            column: 9
          end:
            line: 4
            column: 10
      right:
        type: 'Identifier'
        name: 'x'
        loc:
          start:
            line: 4
            column: 13
          end:
            line: 4
            column: 14
      loc:
        start:
          line: 4
          column: 9
        end:
          line: 4
          column: 14
    eq bi, '__ + __', code, false, false, true

suite 'wildcard' ->
  suite 'single' ->
    test 'simple' ->
      eq 'y + x', 'y + __', code
      eq 'y + x', '__ + __', code

    test 'func name' ->
      eq code-func, 'function __(x, z) { var y = 2; z(); return y + x; }', code

    test 'func args' ->
      eq code-func, 'function addTwo(__, z) { var y = 2; z(); return y + x; }', code
      eq [], 'function addTwo(__) { var y = 2; z(); return y + x; }', code

    test 'func body' ->
      eq [], 'function addTwo(x, z) { __ }', code
      eq code-func, 'function addTwo(x, z) { __; z(); return y + x; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; __; return y + x; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; z(); __; }', code

    test 'sub parts' ->
      eq code-func, 'function addTwo(x, z) { var __ = 2; z(); return y + x; }', code
      eq code-func, 'function addTwo(__, z) { var y = __; z(); return __ + x; }', code

  suite 'array' ->
    test 'simple' ->
      eq code-func, 'function addTwo(x, z) { _$ }', code
      eq code-func, 'function addTwo(_$) { _$ }', code
      eq code-func, 'function __(_$) { _$ }', code

    test '0 elements' ->
      code = 'function f() {}'
      eq code, 'function f(_$) { _$ }', code

    test 'other elements' ->
      eq code-func, 'function addTwo(x, z) { _$; return y + x; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; _$; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; _$; return y + x; }', code

    test 'with an array' ->
      code2 = '[1]'
      eq code2, '[1, _$]', code2

      code = '[1,2,3,4]'
      eq code, '[1, _$]', code
      eq code, '[1, 2, _$]', code
      eq code, '[1, _$, 4]', code

suite 'node type' ->
  test 'simple' ->
    eq code-func, <[ _func_dec _FunctionDeclaration ]>, code

  test 'sub child' ->
    eq 'y + x', '_ident + x', code

  test 'func' ->
    eq code-func, 'function _ident(_ident, _ident) { _var_decs; _exp_statement; _return; }', code
    eq code-func, 'function _ident(x, z) { var _ident = _literal; _ident(); return _ident + _ident; }', code

suite 'matches' ->
  test 'dec' ->
    var-dec =
      type: 'VariableDeclarator'
      id: p 'y'
      init: p '2'
    eq [code-func, 'var y = 2', var-dec], '_dec', code

  test 'exp' ->
    exps = ['z()', 'y + x', '_.each("hi", false)', '_.each', 'underscore.each(/re/gi, null)', 'underscore.each']
    eq exps, '_exp', code

  test 'statement' ->
    statements = ['z()', code-each, code-each2]
    eq statements, '_statement[expression]', code, false
    eq statements, '_Statement[expression]', code, false

suite 'literals' ->
  test 'null' ->
    eq 'null', <[ _null _Null ]>, code

  test 'bool' ->
    eq 'false', <[ _bool _Boolean ]>, code

  test 'num' ->
    eq '2', <[ _num _Number ]>, code

  test 'str' ->
    eq '"hi"', <[ _str _String ]>, code

  test 'regex' ->
    eq '/re/gi', <[ _regex _RegExp ]>, code

suite 'attrs' ->
  prop =
    type: 'Property'
    key: p 'key'
    value: p '2'
    kind: 'init'

  test 'existance' ->
    eq 'y + x', '__[right]', code

  test 'not-there' ->
    eq [], '__[boom]', code

  test 'test subchild' ->
    eq 'y + x', '__[right=x]', code

  test 'not value' ->
    eq 'y + x', '__[right!=2]', code

  test 'primitive value' ->
    eq [prop], '__[kind="init"]', '({key: 2})'
    eq [], '__[kind!="init"]', '({key: 2})'

  test 'either value' ->
    eq '2', '__[value=2]', code
    eq [prop, '2'], '__[value=2]', '({key: 2})'

  test 'complex value' ->
    eq ret, '__[argument=y+x]', code

  test 'combined' ->
    eq 'y + x', '_bi[right=x]', code

  test 'sub' ->
    eq code-func, 'function addTwo(x, z) { var y = 2; z(); return _bi[right=x]; }', code

  test 'deep existance' ->
    eq ret, '__[argument.left]', code

  test 'deep value' ->
    eq ret, '__[argument.left=y]', code

  test 'short hand' ->
    eq ret, '__[arg.l=y]', code

  test 'compound' ->
    eq ret, '__[argument.left=y][argument.right=x]', code

  test 'normal attr use - nothing special' ->
    eq 'obj[k]', 'obj[k]', 'obj[k] = 99'
    eq '({k: 2}[k])', '({k: 2}[k])', 'var z = {k: 2}[k]'
    eq 'x.z[hi]', 'x.z[hi]', 'x.z[hi] = 99'

  test 'normal attr use - wilcards as obj' ->
    code = '
      var z = obj[x[y]];
      var n = {foo: 99}[x[y] = "foo"];
      var m = arr[2];
    '
    eq 'obj[x[y]]', '__[x[y]]', code
    eq '({foo: 99})[x[y] = "foo"]', '__[x[y] = "foo"]', code
    eq 'arr[2]', '_ident[2]', code

suite 'errors' ->
  test 'error processing selector' ->
    assert.throws (-> q '#@C$^HYYC$!$@CV', 'x'), /Error processing selector/

  test 'multiple statements in selector body' ->
    assert.throws (-> q 'x;y', 'x'), /Selector body can't be more than one statement/
