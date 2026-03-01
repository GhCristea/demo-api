open Bun.Test

// Fresh in-memory DB per suite — no shared state between tests
let makeDb = () => Db.open_()  // opens :memory: + runs migrate

describe("ItemRepo - insert + findById roundtrip", () => {
  test("inserted item is retrievable", () => {
    let db    = makeDb()
    // Categories table requires a row first (FK constraint)
    let _cat  = CategoryRepo.insert(db, { name: "Electronics", description: None })
    let input: Schema.Items.insertRow = { name: "Widget", description: Some("blue"), categoryId: 1 }
    let result = ItemRepo.insert(db, input)->Result.flatMap(item => ItemRepo.findById(db, item.id))
    switch result {
    | Ok(item) =>
      expect(item.name)->toEqual("Widget")
      expect(item.description)->toEqual(Some("blue"))
      expect(item.categoryId)->toEqual(1)
    | Error(e) => fail(AppError.toMessage(e))
    }
  })
})

describe("ItemRepo - findById NotFound", () => {
  test("returns NotFound for non-existent id", () => {
    let db = makeDb()
    expect(ItemRepo.findById(db, 999))
    ->toEqual(Error(AppError.NotFound("Item 999 not found")))
  })
})

describe("ItemRepo - delete", () => {
  test("deletes existing item", () => {
    let db   = makeDb()
    let _cat = CategoryRepo.insert(db, { name: "Tools", description: None })
    let result = ItemRepo.insert(db, { name: "ToDelete", description: None, categoryId: 1 })
      ->Result.flatMap(item => ItemRepo.delete(db, item.id))
    expect(result)->toEqual(Ok(()))
  })

  test("returns NotFound for missing item", () => {
    let db = makeDb()
    expect(ItemRepo.delete(db, 999))
    ->toEqual(Error(AppError.NotFound("Item 999 not found")))
  })
})

describe("ItemRepo - insertMany transaction", () => {
  test("all rows inserted atomically", () => {
    let db     = makeDb()
    let _cat   = CategoryRepo.insert(db, { name: "Bulk", description: None })
    let inputs = [
      { Schema.Items.name: "A", description: None, categoryId: 1 },
      { Schema.Items.name: "B", description: None, categoryId: 1 },
    ]
    switch ItemRepo.insertMany(db, inputs) {
    | Ok(items) => expect(Array.length(items))->toEqual(2)
    | Error(e)  => fail(AppError.toMessage(e))
    }
  })
})
