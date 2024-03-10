
import re_int_ineq from 're-int-ineq'

if (module.hot) { module.hot.accept() } // for parcel dev env

window.addEventListener('DOMContentLoaded', () => {
  const operator    = document.getElementById('operator'   ) as HTMLInputElement
  const integer     = document.getElementById('integer'    ) as HTMLInputElement
  const allint      = document.getElementById('allint'     ) as HTMLInputElement
  const anchor      = document.getElementById('anchor'     ) as HTMLInputElement
  const errormsg    = document.getElementById('errormsg'   ) as HTMLElement
  const regexp      = document.getElementById('regexp'     ) as HTMLElement
  const exactmatch  = document.getElementById('exactmatch' ) as HTMLInputElement
  const exactresult = document.getElementById('exactresult') as HTMLElement
  const extract_inp = document.getElementById('extract_inp') as HTMLInputElement
  const extract_out = document.getElementById('extract_out') as HTMLElement
  const btn_copy    = document.getElementById('btn_copy'   ) as HTMLElement
  let re = ''
  const do_upd = () => {
    try {
      re = re_int_ineq(operator.value, integer.valueAsNumber, allint.checked, anchor.checked)
    } catch (ex) {
      errormsg.innerText = '\u00A0' + ex
      errormsg.classList.remove('d-none')
      return
    }
    errormsg.innerText = ''
    errormsg.classList.add('d-none')
    regexp.innerText = re
    btn_copy.classList.add('bi-clipboard')
    btn_copy.classList.remove('bi-clipboard-check-fill')
    if ( new RegExp('^'+re+'$').test(exactmatch.value) ) {
      exactmatch.classList.add('text-success')
      exactmatch.classList.remove('text-danger')
      exactresult.classList.add('bi-check-lg','text-success')
      exactresult.classList.remove('bi-x-lg','text-danger')
      exactresult.innerText = '\u00A0Entire string matches'
    }
    else {
      exactmatch.classList.add('text-danger')
      exactmatch.classList.remove('text-success')
      exactresult.classList.add('bi-x-lg','text-danger')
      exactresult.classList.remove('bi-check-lg','text-success')
      exactresult.innerText = '\u00A0Entire string doesn\'t match'
    }
    const matches = [...(extract_inp.value).matchAll(new RegExp(re,'g'))].map((m)=>m[0])
    if (matches.length) extract_out.innerText = matches.join('\n')
    else extract_out.innerText = '(no matches)'
  }
  operator.addEventListener('change', do_upd)
  integer.addEventListener('change', do_upd)
  allint.addEventListener('change', do_upd)
  anchor.addEventListener('change', do_upd)
  exactmatch.addEventListener('change', do_upd)
  extract_inp.addEventListener('change', do_upd)
  do_upd()
  btn_copy.addEventListener('click', () => {
    navigator.clipboard.writeText(re)
    btn_copy.classList.add('bi-clipboard-check-fill')
    btn_copy.classList.remove('bi-clipboard')
  })
})
