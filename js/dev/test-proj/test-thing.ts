import re_int_ineq from 're-int-ineq'

if ( re_int_ineq('<',3) !== '(?<![0-9])[0-2](?![0-9])' ) throw new Error
if ( re_int_ineq('<',3,true) !== '(?:(?<![-0-9])[0-2]|-0|-[1-9][0-9]*)(?![0-9])' ) throw new Error
if ( re_int_ineq('<',3,true,false) !== '(?:[0-2]|-0|-[1-9][0-9]*)' ) throw new Error
console.log('OK!')
