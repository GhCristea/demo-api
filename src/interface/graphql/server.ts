import { ApolloServer } from '@apollo/server'
import type { ApolloServerOptions } from '@apollo/server'
import { typeDefs } from './schema'
import { resolvers } from './resolvers'

/**
 * Apollo Server configuration.
 *
 * Initializes the GraphQL server with:
 * - Type definitions (schema)
 * - Resolvers (implementation)
 * - Default formatting options
 */
const serverConfig: ApolloServerOptions<any> = {
  typeDefs,
  resolvers,
  formatError: (error: any) => {
    // Log errors for debugging
    console.error('[Apollo Error]', {
      message: error.message,
      code: error.extensions?.code,
      path: error.path,
    })

    // Return formatted error to client
    return {
      message: error.message,
      extensions: error.extensions,
    }
  },
}

/**
 * Create and export Apollo Server instance.
 *
 * Usage:
 * ```ts
 * const apollo = createApolloServer()
 * await apollo.start()
 * app.use('/graphql', expressMiddleware(apollo))
 * ```
 */
export const createApolloServer = () => new ApolloServer(serverConfig)
