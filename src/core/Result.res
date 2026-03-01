// Railway-Oriented Programming combinators
// Composes result-returning functions without nested switch
// All functions are pure — no side effects

let map = (result: result<'a, 'e>, f: 'a => 'b): result<'b, 'e> =>
  switch result {
  | Ok(v) => Ok(f(v))
  | Error(_) as err => err
  }

let flatMap = (result: result<'a, 'e>, f: 'a => result<'b, 'e>): result<'b, 'e> =>
  switch result {
  | Ok(v) => f(v)
  | Error(_) as err => err
  }

let fromOption = (opt: option<'a>, err: 'e): result<'a, 'e> =>
  switch opt {
  | Some(v) => Ok(v)
  | None => Error(err)
  }

let mapError = (result: result<'a, 'e>, f: 'e => 'f): result<'a, 'f> =>
  switch result {
  | Ok(_) as ok => ok
  | Error(e) => Error(f(e))
  }
