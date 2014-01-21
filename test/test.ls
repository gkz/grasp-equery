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
  test 'version' ->
    fs = require 'fs'
    current-version = JSON.parse fs.read-file-sync 'package.json', 'utf8' .version
    assert.strict-equal (require '..').VERSION, current-version

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

  test 'expression statements' ->
    eq 'f()', 'f()', 'f();'
    eq {type: 'ExpressionStatement', expression: p 'f()'}, 'f();', 'f();'
    eq {type: 'ExpressionStatement', expression: p '2 + 2'}, '2 + 2;', '2 + 2;'

  test 'normal object use' ->
    code = '({_: blah})'
    eq code, '({_:blah})', code

    code2 = '({a: b})'
    eq code2, '({a:b})', code2

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

    test 'object' ->
      code = '({a: 1, b: 2, c: 3})'
      eq code, '{_:_, b:2, _:_}', code
      eq [], '{_:_, b:2}', code
      eq [], '{b:2, _:_}', code
      eq code, '{_:_, _:_, _:_}', code

  suite 'array' ->
    test 'simple' ->
      eq code-func, 'function addTwo(x, z) { _$ }', code
      eq code-func, 'function addTwo(_$) { _$ }', code
      eq code-func, 'function __(_$) { _$ }', code

    test '0 elements' ->
      code = 'function f() {}'
      eq code, 'function f(_$) { _$ }', code
      eq '[]', '[]', '[]'
      eq '[]', '[_$]', '[]'

    test 'other elements' ->
      eq code-func, 'function addTwo(x, z) { _$; return y + x; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; _$; }', code
      eq code-func, 'function addTwo(x, z) { var y = 2; _$; return y + x; }', code

    test 'elements in the middle' ->
      eq code-func, 'function addTwo(x, z) { _$; z(); _$ }', code

    suite 'list' ->
      code = '[1,2,3,4]'

      test 'one element' ->
        code = '[1]'
        eq code, '[1, _$]', code
        eq code, '[_$, 1]', code

      test 'multiple elements' ->
        eq code, '[_$]', code
        eq code, '[_$, 1, _$, 2, _$, 3, _$, 4, _$]', code

        eq [], '[3, _$]', code
        eq [], '[_$, 3]', code

        eq code, '[1, _$]', code
        eq code, '[1, 2, _$]', code

        eq code, '[_$, 4]', code
        eq code, '[_$, 3, 4]', code

        eq code, '[1, _$, 4]', code
        eq code, '[1, _$, 3, 4]', code

      test 'in the middle single el' ->
        code = '[1]'
        eq code, '[_$, 1, _$]', code

      test 'in the middle multiple el' ->
        eq code, '[_$, 3, _$]', code
        eq [], '[_$, 3]', code
        eq code, '[_$, 2, 3, _$]', code
        eq [], '[_$, 7, _$]', code

      test 'in the middle multiple el hanging el' ->
        eq code, '[_$, 4, _$]', code
        eq code, '[_$, 1, _$]', code

        eq code, '[_$, 1, 2, 3, 4, _$]', code

      test 'els in middle and sides' ->
        code = '[1,2,3,4,5]'
        eq code, '[1,_$,3,_$,5]', code
        eq [], '[1,_$,5,_$,5]', code
        eq code, '[1,_$,2,3,_$,5]', code
        eq code, '[1,_$,2,3,4,_$,5]', code
        eq [], '[1,_$,2,3,4,5,_$,5]', code

      test '_$ in middle and sides' ->
        code = '[1,2,3,4,5]'
        eq code, '[_$, 1, _$, 4, _$]', code
        eq [], '[_$, 5, _$, 4, _$]', code

    suite 'object' ->
      code = '({w: 0, x: 1, y: 2, z: 3})'

      test 'all' ->
        eq code, '({_:$})', code

      test 'start' ->
        eq code, '{_:$, y:2, z:3}', code

      test 'end' ->
        eq code, '{w:0, x:1, _:$}', code

      test 'surround' ->
        eq code, '{_:$, x:1, _:$}', code

      test 'middle' ->
        eq code, '{w:0, _:$, z:3}', code

      test 'hanging' ->
        eq code, '{w:0, x:1, y:2, z: 3, _:$}', code

      test 'fail' ->
        eq [], '{_:$, x:0, _:$}', code
        eq [], '{x:1, _:$, z:3}', code

suite 'named wildcard' ->
  test 'simple' ->
    bi =
      type: 'BinaryExpression'
      left: p 'y'
      right: p 'x'
      operator: '+'

    bi._named =
      a: p 'x'
    eq bi, 'y + $a', code

    bi._named =
      a: p 'y'
      b: p 'x'
    eq bi, '$a + $b', code

  test 'two of the same' ->
    same =
      type: 'BinaryExpression'
      left: p '2'
      right: p '2'
      operator: '+'
      _named:
        a: p '2'

    eq same, '$a + $a', '2 + 2'
    eq [], '$a + $a', '1 + 2'

  test 'object' ->
    code = '({a:1, b:2, c:3})'
    obj = p code
    obj._named =
      b:
        key: p 'b'
        value: p '2'
        kind: 'init'

    eq obj, '{a:1, $:b, c:3}', code

  suite 'with _$' ->
    code = 'f(1,2,3,4)'
    call = p code

    test 'first' ->
      call._named =
        a: p '1'
      eq call, 'f($a, _$)', code

    test 'first multiple' ->
      call._named =
        a: p '1'
        b: p '2'
      eq call, 'f($a, $b, _$)', code

    test 'last' ->
      call._named =
        b: p '4'
      eq call, 'f(_$, $b)', code

    test 'last multiple' ->
      call._named =
        a: p '3'
        b: p '4'
      eq call, 'f(_$, $a, $b)', code

    test 'ends' ->
      call._named =
        a: p '1'
        b: p '4'
      eq call, 'f($a, _$, $b)', code

    test 'ends multiple' ->
      call._named =
        a: p '1'
        c: p '2'
        d: p '3'
        b: p '4'
      eq call, 'f($a, $c, _$, $d, $b)', code

    test 'with literals simple' ->
      call._named =
        a: p '1'
        b: p '4'
      eq call, 'f($a, _$, 3, _$,  $b)', code

    test 'with literals complex' ->
      call._named =
        a: p '1'
        c: p '3'
        b: p '4'
      eq call, 'f($a, _$, 2, $c, _$,  $b)', code

    test 'multiple the same' ->
      call = p 'f(1,2,2,3,4)'
      call._named =
        a: p '1'
        c: p '2'
        b: p '4'
      eq call, 'f($a, _$, 2, $c, _$,  $b)', 'f(1,2,2,3,4)'
      eq call, 'f($a, _$, $c, $c, _$,  $b)', 'f(1,2,2,3,4)'

  suite 'named array wildcard' ->
    code = '[1,2,3,4]'
    array = p code

    test 'all' ->
      array._named = elements: [(p '1'), (p '2'), (p '3'), (p '4')]
      eq array, '[_$elements]', code

    test 'none' ->
      array._named = elements: []
      eq array, '[1, 2, 3, 4, _$elements]', code

    test 'first' ->
      array._named = elements: [(p '1'), (p '2'), (p '3')]
      eq array, '[_$elements, 4]', code

    test 'last' ->
      array._named = elements: [(p '2'), (p '3'), (p '4')]
      eq array, '[1, _$elements]', code

    test 'middle' ->
      array._named = elements: [(p '2'), (p '3')]
      eq array, '[1, _$elements, 4]', code

    test 'interspersed' ->
      code = '[1,2,3,4,5,6,7]'
      array = p code
      array._named =
        a: [(p '2'), (p '3')]
        b: [(p '5'), (p '6')]
      eq array, '[1, _$a, 4, _$b, 7]', code

      array._named =
        a: [(p '2')]
        b: [(p '4')]
        c: [(p '6')]
      eq array, '[1, _$a, 3, _$b, 5, _$c, 7]', code

    test 'statements' ->
      code =
        '''
        function f(x) {
          g(x);
          obj[x] = x * x;
          return x;
        }
        '''
      func = p code
      func._named =
        statements:
          * type: 'ExpressionStatement'
            expression: p 'obj[x] = x * x;'
          * type: 'ReturnStatement'
            argument: p 'x'

      eq func, 'function f(x) { g(x); _$statements }', code

  suite 'in object' ->
    code = '({w: 0, x: 1, y: 2, z: 3})'
    obj = p code

    test 'all' ->
      obj._named = props: [{key: (p k), value: (p v), kind: 'init'} for k, v of {w: '0', x: '1', y: '2', z: '3'}]
      eq obj, '({_:$props})', code

    test 'start' ->
      obj._named = begin: [{key: (p k), value: (p v), kind: 'init'} for k, v of {w: '0', x: '1'}]
      eq obj, '{_:$begin, y:2, z:3}', code

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
