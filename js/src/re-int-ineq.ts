/**
 * Regular Expression Integer Inequalities
 * =======================================
 *
 * This module provides a single function, `re_int_ineq`, which generates
 * regular expressions that match integers that fulfill a specified inequality
 * (greater than, less than, and so on). By default, only non-negative integers
 * are matched (minus signs are ignored), and optionally all integers can be
 * matched, including negative. Integers with leading zeros are never matched.
 *
 * **Note:** Normally, this is not a task for regular expressions, instead it is
 * often preferable to use regular expressions or other methods to extract the
 * numbers from a string and then use normal numeric comparison operators.
 * However, there are cases where this module can be useful, for example when
 * embedding these regular expressions as part of a larger expression or
 * grammar, or when dealing with an API that only accepts regular expressions.
 *
 * The generated regular expressions are valid in Perl, Python, and JavaScript
 * ES2018 or later, and likely in other languages that support lookaround
 * assertions with the same syntax.
 *
 * See Also
 * --------
 *
 * **Perl version:** <https://metacpan.org/pod/Regexp::IntInequality>
 *
 * **Python port:** <https://pypi.org/project/re-int-ineq/>
 * (includes a command-line interface)
 *
 * Author, Copyright and License
 * -----------------------------
 *
 * Copyright (c) 2024 Hauke Daempfling (haukex@zero-g.net).
 *
 * This file is part of the "Regular Expression Integer Inequalities" library.
 *
 * This library is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>
 *
 * @module
 */

/* CODE COMMENTS: This file is lacking code comments because it is a port
 * of the Perl version. Please see that for information on the code flow. */

const _RNG_GT  = [...Array(7).keys()].map((x)=>`[${x+1}-9]`).concat('[89]', '9', '(?!)')
const _RNG_LT0 = ['(?!)', '0', '[01]'].concat( [...Array(7).keys()].map((x)=>`[0-${x+2}]`) )
const _RNG_LT1 = ['(?!)', '(?!)', '1', '[12]'].concat( [...Array(6).keys()].map((x)=>`[1-${x+3}]`) )

const _ALLINT_ZN = new Set(['-0','0','-[1-9][0-9]*'])
const _ALLINT_ZP = new Set(['-0','0','[1-9][0-9]*'])
const _ALLINT_NN = new Set(['0','[1-9][0-9]*'])

const _PREFIX_NN = '(?<![0-9])'
const _PREFIX_AI = '(?<![-0-9])'
const _SUFFIX = '(?![0-9])'

const _ANY_ZP = new Set( [...Array(8).keys()].map((i)=> `[0-${i+2}]`).concat( '[01]',  '[1-9]?[0-9]') )
const _ANY_ZN = new Set( [...Array(8).keys()].map((i)=>`-[0-${i+2}]`).concat('-[01]', '-[1-9]?[0-9]') )

/**
 * Generates a regex that matches integers according to its parameters.
 *
 * Note the regular expressions will grow significantly the more digits are in
 * the integer. I suggest not to generate regular expressions from unbounded
 * user input.
 *
 * @param op - The operator the regex should implement, one of `">"`, `">="`,
 *   `"<"`, `"<="`, `"!="`, or `"=="` (the latter is provided simply for
 *   completeness, despite the name of this module).
 *
 * @param n - The integer against which the regex should compare.
 *   May only be negative when `allint` is true.
 *
 * @param allint - If `false` (the default), the generated regex will only
 *   cover positive integers and zero, and `n` may not be negative. **Note**
 *   that in this case, any minus signs before integers are not included in the
 *   regex. This means that when using the regex, for example, to extract
 *   integers greater than 10 from the string `"3 5 15 -7 -12"`, it will match
 *   `"15"` **and** `"12"`!
 *
 *   —•—
 *
 *   If ``True``, the generated regex will cover all integers, including
 *   negative, and ``integer`` may also be any integer. Note that all
 *   generated regexes that match zero will also match ``"-0"`` and vice
 *   versa.
 *
 * @param anchor - This is `true` by default, meaning the regex will have
 *   zero-width assertions (a.k.a. anchors) surrounding the expression in order
 *   to prevent matches inside of integers. For example, when extracting
 *   integers less than 20 from the string `"1199 32 5"`, the generated regex
 *   will by default not extract the `"11"` or `"19"` from `"1199"`, and will
 *   only match `"5"`. On the other hand, any non-digit characters (including
 *   minus signs) are considered delimiters: extracting all integers less than
 *   5 from the string `"2x3-3-24y25"` with `allint` turned on will result in
 *   `"2"`, `"3"`, `"-3"`, and `"-24"`.
 *
 *   —•—
 *
 *   This behavior is useful if you are extracting numbers from a longer
 *   string. If you want to validate that a string contains *only* an integer,
 *   then you will need to add additional anchors. For example, you might add
 *   `^` before the generated regex and `$` after, keeping in mind not to turn
 *   on the `multiline` (`m`) flag, as that changes the meaning of these
 *   anchors. However, this task is more commonly done by first checking that
 *   the string is a valid integer in general, and then using normal numeric
 *   comparisons to check that it is in the range you expect.
 *
 *   —•—
 *
 *   If on the other hand you want to turn off the default anchors described
 *   above, perhaps because you want to implement your own, then you can set
 *   this option to `false`. Repeating the above example, extracting integers
 *   less than 20 from the string `"1199 32 5"` with this option off and no
 *   additional anchors results in `"11"`, `"9"`, `"9"`, `"3"`, `"2"`, and
 *   `"5"` - so use this feature with caution and testing!
 *
 * @returns The regular expression. It is returned as a string rather than a
 *   precompiled regex so it can more easily be embedded in larger expressions.
 */
export default function re_int_ineq(op :string, n :number, allint :boolean = false, anchor :boolean = true): string {
  if (!Number.isSafeInteger(n)) throw new TypeError('invalid number')
  if (!allint && n<0) throw new RangeError('cant pass an integer <0 unless allint is set')

  if (op==='==') {
    if (!anchor) return n==0 && allint ? '-?0' : `${n}`
    if (n==0 && allint) return `(?:${_PREFIX_AI}0|-0)${_SUFFIX}`
    if (n<0) return `${n}${_SUFFIX}`
    return allint ? `${_PREFIX_AI}${n}${_SUFFIX}` : `${_PREFIX_NN}${n}${_SUFFIX}`
  }
  if (op==='!=') {
    if (!anchor) {
      if (n==0)  return (allint?'-?':'')+     '[1-9][0-9]*'
      return `(?!${n})`+(allint?'-?':'')+'(?:0|[1-9][0-9]*)'
    }
    if (allint) return '(?!'+(n==0?'-?0':`${n}`)
      +`${_SUFFIX})(?:${_PREFIX_AI}(?:0|[1-9][0-9]*)|-0|-[1-9][0-9]*)${_SUFFIX}`
    return `(?!${n}${_SUFFIX})${_PREFIX_NN}(?:0|[1-9][0-9]*)${_SUFFIX}`
  }

  const mkre = (se :Set<string>) => {
    /* istanbul ignore next */
    if (!se.size) throw new Error('assertion failed')

    // Set.intersection is only spec'd, not implemented
    if ( Array.from(se).some((e)=>_ANY_ZP.has(e)) ) se.delete( '0')
    if ( Array.from(se).some((e)=>_ANY_ZN.has(e)) ) se.delete('-0')

    const pos :Array<string> = []
    const neg :Array<string> = []
    se.forEach((e) => (e.startsWith('-')?neg:pos).push(e) )
    pos.sort()
    neg.sort()

    const all :Array<string> = []

    if (!anchor) all.push(...pos)
    else if (pos.length) all.push( (allint?_PREFIX_AI:_PREFIX_NN)
      +( pos.length>1 ? '(?:'+pos.join('|')+')' : pos[0] ) )

    if (neg.length<6) all.push(...neg)
    else all.push( '-(?:'+neg.map((e)=>e.substring(1)).join('|')+')' )

    /* istanbul ignore next */
    if (!all.length) throw new Error('assertion failed')
    return ( all.length>1 ? '(?:'+all.join('|')+')' : all[0] )
      +( anchor ? _SUFFIX : '' )
  }

  let gt_not_lt :boolean
  if (op==='>'||op==='>=') {
    if (op==='>=') n--
    gt_not_lt = true
  }
  else if (op==='<'||op==='<=') {
    if (op==='<=') n++
    gt_not_lt = false
  }
  else throw new RangeError('unknown operator')

  if (n==0 && !gt_not_lt && !allint) return '(?!)'
  if (n==-1 && gt_not_lt) return mkre( allint ? _ALLINT_ZP : _ALLINT_NN )
  if (n==0) return mkre( new Set([ gt_not_lt ? '[1-9][0-9]*' : '-[1-9][0-9]*' ]) )

  const reflect = allint && n<0
  if (reflect) gt_not_lt = !gt_not_lt
  const an :string = ( reflect ? -n : n ).toString()
  const minus = reflect ? '-' : ''
  /* istanbul ignore next */
  if ( parseInt(an)<1 ) throw new Error('assertion failed')

  const subex = new Set<string>()

  if (allint && !gt_not_lt)
    (reflect ? _ALLINT_NN : _ALLINT_ZN).forEach((e)=>subex.add(e))

  if (gt_not_lt) {
    if (an.length==1) subex.add( `${minus}[1-9][0-9]+` )
    else subex.add( `${minus}[1-9][0-9]{${an.length},}` )
  }
  else {
    if (an.length>3) {
      subex.add( `${minus}0` )
      subex.add( `${minus}[1-9][0-9]{0,${an.length-2}}` )
    }
    else if (an.length>2)
      subex.add( `${minus}[1-9]?[0-9]` )
    else if (an.length>1)
      subex.add( `${minus}[0-9]` )
  }

  [...an].forEach( (d,i) => {
    const r = an.length-i-1
    const rest = !r ? '' : r==1 ? '[0-9]' : `[0-9]{${r}}`
    const dn = parseInt(d)
    const rng = gt_not_lt ? _RNG_GT[dn] : an.length==1 || i ? _RNG_LT0[dn] : _RNG_LT1[dn]
    if ( rng !== '(?!)' )
      subex.add( minus + an.substring(0,i) + rng + rest )
  })

  return mkre(subex)
}