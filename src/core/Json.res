// Lightweight JSON construction helpers
// Keeps domain toJson functions concise — no external lib needed

let str  = Js.Json.string
let num  = Js.Json.number
let null = Js.Json.null
let int  = (n: int) => num(Int.toFloat(n))
let opt  = (o: option<string>) => o->Option.map(str)->Option.getOr(null)
let obj  = (fields: array<(string, Js.Json.t)>) => fields->Js.Dict.fromArray->Js.Json.object_
