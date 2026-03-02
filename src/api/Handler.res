// Shared handler contract — imported by all controllers and Router
// Decouples controllers from each other and from Router internals
type t = (Bun.request, Js.Dict.t<string>) => promise<Bun.response>
