import { GraphQLError } from 'graphql'
import type { ItemRow, CategoryRow } from '@/orm'
import { itemRepository, categoryRepository } from '@/orm'
import { AppError, NotFoundError, ValidationError } from '@/core/errors'
import type { ZodError } from 'zod'

/**
 * GraphQL Resolvers.
 *
 * An adapter layer that translates GraphQL arguments into domain service calls.
 * No business logic here—we delegate to repositories.
 *
 * Key Design:
 * 1. Zero business logic—pure delegation to repositories
 * 2. Error handling: Domain errors → GraphQL errors
 * 3. Validation happens in repository/service layer (Zod schemas)
 * 4. Type safety: Queries and mutations return proper types
 */

/**
 * Convert domain errors to GraphQL errors.
 *
 * Maps domain layer exceptions to appropriate GraphQL error codes.
 * This centralizes error handling across the resolver layer.
 */
const handleError = (error: unknown): never => {
  console.error('[GraphQL Error]', error)

  if (error instanceof NotFoundError) {
    throw new GraphQLError(error.message, {
      extensions: {
        code: 'NOT_FOUND',
        http: { status: 404 },
      },
    })
  }

  if (error instanceof ValidationError) {
    throw new GraphQLError(error.message, {
      extensions: {
        code: 'BAD_USER_INPUT',
        http: { status: 400 },
        issues: (error as any).issues,
      },
    })
  }

  if (error instanceof AppError) {
    throw new GraphQLError(error.message, {
      extensions: {
        code: 'INTERNAL_SERVER_ERROR',
        http: { status: 500 },
      },
    })
  }

  // Zod validation errors
  if ((error as any)?.errors && Array.isArray((error as any).errors)) {
    const zodError = error as ZodError
    throw new GraphQLError('Validation failed', {
      extensions: {
        code: 'BAD_USER_INPUT',
        http: { status: 400 },
        issues: zodError.errors.map(e => ({
          path: e.path.join('.'),
          message: e.message,
        })),
      },
    })
  }

  // Generic error
  throw new GraphQLError('Internal server error', {
    extensions: {
      code: 'INTERNAL_SERVER_ERROR',
      http: { status: 500 },
    },
  })
}

/**
 * Query resolvers (read operations).
 */
export const queryResolvers = {
  Query: {
    /**
     * List items with optional search and limit.
     */
    async items(
      _: any,
      args: { search?: string; limit?: number },
    ): Promise<ItemRow[]> {
      try {
        if (args.search) {
          return await itemRepository.search(args.search)
        }
        return await itemRepository.findAll(args.limit || 100)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Get single item by ID.
     */
    async item(_: any, args: { id: number }): Promise<ItemRow | undefined> {
      try {
        return await itemRepository.findById(args.id)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Find items by category.
     */
    async itemsByCategory(
      _: any,
      args: { categoryId: number; limit?: number },
    ): Promise<ItemRow[]> {
      try {
        return await itemRepository.findByCategory(args.categoryId)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Find items within price range.
     */
    async itemsByPrice(
      _: any,
      args: { minPrice: number; maxPrice: number; limit?: number },
    ): Promise<ItemRow[]> {
      try {
        return await itemRepository.findByPriceRange(
          args.minPrice,
          args.maxPrice,
        )
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Get all categories sorted.
     */
    async categories(): Promise<CategoryRow[]> {
      try {
        return await categoryRepository.findAllSorted()
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Get single category by ID.
     */
    async category(
      _: any,
      args: { id: number },
    ): Promise<CategoryRow | undefined> {
      try {
        return await categoryRepository.findById(args.id)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Search categories by name.
     */
    async searchCategories(
      _: any,
      args: { query: string },
    ): Promise<CategoryRow[]> {
      try {
        return await categoryRepository.searchByName(args.query)
      } catch (error) {
        handleError(error)
      }
    },
  },
}

/**
 * Mutation resolvers (write operations).
 */
export const mutationResolvers = {
  Mutation: {
    /**
     * Create a single item.
     * Validation happens automatically in repository via Zod schema.
     */
    async createItem(
      _: any,
      args: {
        input: {
          name: string
          description?: string
          categoryId: number
          price: number
        }
      },
    ): Promise<ItemRow> {
      try {
        return await itemRepository.createItem(args.input)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Create multiple items in batch.
     */
    async createItems(
      _: any,
      args: {
        input: Array<{
          name: string
          description?: string
          categoryId: number
          price: number
        }>
      },
    ): Promise<ItemRow[]> {
      try {
        return Promise.all(
          args.input.map(item => itemRepository.createItem(item)),
        )
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Update an item.
     */
    async updateItem(
      _: any,
      args: {
        id: number
        input: {
          name?: string
          description?: string
          categoryId?: number
          price?: number
        }
      },
    ): Promise<ItemRow | null> {
      try {
        return (await itemRepository.updateItem(args.id, args.input)) || null
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Delete a single item.
     */
    async deleteItem(
      _: any,
      args: { id: number },
    ): Promise<ItemRow | null> {
      try {
        const item = await itemRepository.findById(args.id)
        if (!item) return null
        await itemRepository.delete(args.id)
        return item
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Delete multiple items by IDs.
     */
    async deleteItems(
      _: any,
      args: { ids: number[] },
    ): Promise<ItemRow[]> {
      try {
        const items: ItemRow[] = []
        for (const id of args.ids) {
          const item = await itemRepository.findById(id)
          if (item) {
            items.push(item)
            await itemRepository.delete(id)
          }
        }
        return items
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Create a category.
     */
    async createCategory(
      _: any,
      args: {
        input: {
          name: string
          description?: string
        }
      },
    ): Promise<CategoryRow> {
      try {
        return await categoryRepository.createCategory(args.input)
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Update a category.
     */
    async updateCategory(
      _: any,
      args: {
        id: number
        input: {
          name?: string
          description?: string
        }
      },
    ): Promise<CategoryRow | null> {
      try {
        return (
          (await categoryRepository.updateCategory(args.id, args.input)) ||
          null
        )
      } catch (error) {
        handleError(error)
      }
    },

    /**
     * Delete a category.
     */
    async deleteCategory(
      _: any,
      args: { id: number },
    ): Promise<CategoryRow | null> {
      try {
        const category = await categoryRepository.findById(args.id)
        if (!category) return null
        await categoryRepository.delete(args.id)
        return category
      } catch (error) {
        handleError(error)
      }
    },
  },
}

/**
 * Field resolvers (type resolvers).
 * Handle nested fields like Item.category.
 */
export const fieldResolvers = {
  Item: {
    /**
     * Resolve the category relationship.
     * Called when category field is requested in a query.
     */
    async category(parent: ItemRow): Promise<CategoryRow | null> {
      try {
        if (!parent.categoryId) return null
        return (await categoryRepository.findById(parent.categoryId)) || null
      } catch (error) {
        console.error('[Field Resolver Error]', error)
        return null
      }
    },
  },
}

/**
 * Combine all resolvers.
 */
export const resolvers = [
  queryResolvers,
  mutationResolvers,
  fieldResolvers,
]
