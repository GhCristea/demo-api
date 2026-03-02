open Bun.Test

describe("CategoryService - findById", () => {
  test("returns category on success", () => {
    let svc = CategoryService.mock()
    expect(svc.findById(1))->toEqual(Ok(Fixtures.mockCategory))
  })

  test("returns NotFound for missing id", () => {
    let svc: CategoryService.t = {
      ...CategoryService.mock(),
      findById: id => Error(AppError.NotFound(`Category ${Int.toString(id)} not found`)),
    }
    expect(svc.findById(99))->toEqual(Error(AppError.NotFound("Category 99 not found")))
  })
})

describe("CategoryService - findByItemId", () => {
  test("returns category for valid item", () => {
    let svc = CategoryService.mock()
    expect(svc.findByItemId(1))->toEqual(Ok(Fixtures.mockCategory))
  })
})
