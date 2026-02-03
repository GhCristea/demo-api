/**
 * GraphQL Interface Layer.
 *
 * Exports:
 * - Schema definitions
 * - Resolvers (queries, mutations, field resolvers)
 * - Apollo Server setup
 *
 * Architecture:
 * - schema.ts: Type definitions (SDL)
 * - resolvers.ts: Business logic adapters (zero logic, pure delegation)
 * - server.ts: Apollo Server configuration
 */

export { typeDefs } from './schema'
export { resolvers, queryResolvers, mutationResolvers, fieldResolvers } from './resolvers'
export { createApolloServer } from './server'
