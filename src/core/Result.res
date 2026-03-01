// Railway-Oriented Programming combinators
// Composes result-returning functions without nested switch
// All functions are pure — no side effects

let map = (result: result<'a, 'e>, f: 'a => 'b): result<'b, 'e> =>
  switch result {
  | Ok(v)    => Ok(f(v))
  | Error(_) as err => err
  }

let flatMap = (result: result<'a, 'e>, f: 'a => result<'b, 'e>): result<'b, 'e> =>
  switch result {
  | Ok(v)    => f(v)
  | Error(_) as err => err
  }

let fromOption = (opt: option<'a>, err: 'e): result<'a, 'e> =>
  switch opt {
  | Some(v) => Ok(v)
  | None    => Error(err)
  }

let mapError = (result: result<'a, 'e>, f: 'e => 'f): result<'a, 'f> =>
  switch result {
  | Ok(_) as ok => ok
  | Error(e)    => Error(f(e))
  }

// Side-effect in Ok lane — value passes through unchanged
let tap = (result: result<'a, 'e>, f: 'a => unit): result<'a, 'e> => {
  switch result { | Ok(v) => f(v) | Error(_) => () }
  result
}

// Side-effect in Error lane — error passes through unchanged
let tapError = (result: result<'a, 'e>, f: 'e => unit): result<'a, 'e> => {
  switch result { | Error(e) => f(e) | Ok(_) => () }
  result
}

// Sequence an array of results — first Error wins (short-circuit)
let all = (results: array<result<'a, 'e>>): result<array<'a>, 'e> =>
  results->Array.reduce(Ok([]), (acc, r) =>
    acc->flatMap(xs => r->map(x => Array.concat(xs, [x])))
  )
