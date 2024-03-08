import {expect, test} from '@jest/globals'
import re_int_ineq from '../re-int-ineq'
import * as testcases from './testcases.json'

testcases['manual_tests'].forEach( (tc) => {
  if (typeof tc === 'string') return
  const [op, n, ai, anc, exp] = tc
  test(tc.toString(), () => {
    expect(re_int_ineq(<string>op, <number>(typeof n === 'string' ? parseInt(n) : n), <boolean>ai, <boolean>anc)).toStrictEqual(exp)
  })
})

testcases['extraction'].forEach( (tc) => {
  if (typeof tc === 'string') return
  const [op, n, ai, anc, str, ...exp] = tc
  test(tc.toString(), () => {
    const re = new RegExp(re_int_ineq(<string>op, <number>(typeof n === 'string' ? parseInt(n) : n), <boolean>ai, <boolean>anc), 'g')
    expect( [...(<string>str).matchAll(re)].map((m)=>m[0]) ).toStrictEqual(exp)
  })
})

const nevermatch :string[] = testcases['zeroes_nevermatch'].flatMap((e)=>[`0${e}`,`00${e}`,`-0${e}`,`-00${e}`])
testcases['zeroes'].forEach( (tc) => {
  const [op, n, mz] = tc  // eslint-disable-line prefer-const
  if (!n?.toString().startsWith('-')) {
    const rn = new RegExp( '^'+re_int_ineq(<string>op, <number>(typeof n === 'string' ? parseInt(n) : n))+'$' )
    test('N,'+tc.toString(), ()=>{
      if (mz) expect('0').toMatch(rn)
      else expect('0').not.toMatch(rn)
      expect('-0').not.toMatch(rn)
      nevermatch.forEach((e)=>expect(e).not.toMatch(rn))
    })
  }
  const rz = new RegExp( '^'+re_int_ineq(<string>op, <number>(typeof n === 'string' ? parseInt(n) : n), true)+'$' )
  test('z,'+tc.toString(), ()=>{
    if (mz) {
      expect('0').toMatch(rz)
      expect('-0').toMatch(rz)
    } else {
      expect('0').not.toMatch(rz)
      expect('-0').not.toMatch(rz)
    }
    nevermatch.forEach((e)=>expect(e).not.toMatch(rz))
  })
})

testcases['errorcases'].forEach( (tc) => {
  if (typeof tc === 'string') return
  // the following `as` is just to trick TypeScript into thinking `tc` is valid, the test cases are *supposed* to cause failures
  test(tc.toString(), ()=>expect( ()=>re_int_ineq(...tc as [string, number, boolean, boolean]) ).toThrow())
})

function run_rangetests(cases :Array<number>, ai :boolean) {
  cases.forEach((n)=>{
    test((ai?'Z':'N')+n.toString(), ()=>{
      const rlt = new RegExp('^'+re_int_ineq('<',  n, ai)+'$')
      const rle = new RegExp('^'+re_int_ineq('<=', n, ai)+'$')
      const rgt = new RegExp('^'+re_int_ineq('>',  n, ai)+'$')
      const rge = new RegExp('^'+re_int_ineq('>=', n, ai)+'$')
      const rne = new RegExp('^'+re_int_ineq('!=', n, ai)+'$')
      const req = new RegExp('^'+re_int_ineq('==', n, ai)+'$')
      cases.forEach((i)=> {
        const is = i.toString()
        if (i<n)  expect(is).toMatch(rlt)
        else  expect(is).not.toMatch(rlt)
        if (i<=n) expect(is).toMatch(rle)
        else  expect(is).not.toMatch(rle)
        if (i>n)  expect(is).toMatch(rgt)
        else  expect(is).not.toMatch(rgt)
        if (i>=n) expect(is).toMatch(rge)
        else  expect(is).not.toMatch(rge)
        if (i!=n) expect(is).toMatch(rne)
        else  expect(is).not.toMatch(rne)
        if (i==n) expect(is).toMatch(req)
        else  expect(is).not.toMatch(req)
      })
    })
  })
}

const nonneg_testranges = testcases['nonneg_testranges'].flatMap((e) => {
  const [start, stop] = e as [number, number]
  return [...Array(stop-start).keys()].map((x)=>x+start)
} )
run_rangetests(nonneg_testranges, false)

const allint_testranges = testcases['allint_testranges'].flatMap((e) =>{
  const [start, stop] = e as [number, number]
  return [...Array(stop-start).keys()].flatMap((x)=>[x+start,-x-start])
})
run_rangetests(allint_testranges, true)
