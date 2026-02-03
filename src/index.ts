import express, { type Application } from 'express'
import cors from 'cors'
import { createApolloServer } from '@/interface/graphql'
import { expressMiddleware } from '@apollo/server/express4'
import { itemsRouter } from '@/interface/rest/routers/itemsRouter'
import { errorHandler } from '@/interface/rest/middleware/errorHandler'

const app: Application = express()
const PORT = process.env.PORT ?? 3001

// Middleware
app.use(cors())
app.use(express.json())

// REST API Mount
app.use('/rest/items', itemsRouter)

// Health check endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() })
})

let server: any

const start = async () => {
  try {
    // Initialize GraphQL Server
    const apollo = createApolloServer()
    await apollo.start()
    console.log('✓ Apollo GraphQL Server started')

    // Mount GraphQL Middleware
    app.use('/graphql', expressMiddleware(apollo))

    // Global Error Handler (must be last for REST API)
    app.use(errorHandler)

    // Start HTTP Server
    server = app.listen(PORT, () => {
      console.log(`\n╔════════════════════════════════════════╗`)
      console.log(`║     Demo API - Hexagonal Architecture  ║`)
      console.log(`╚════════════════════════════════════════╝`)
      console.log(`\n📡 Server running on port ${PORT}`)
      console.log(`\n🔗 API Endpoints:`)
      console.log(`   • REST API:       http://localhost:${PORT}/rest`)
      console.log(`   • GraphQL API:    http://localhost:${PORT}/graphql`)
      console.log(`   • Health Check:   http://localhost:${PORT}/health`)
      console.log(`\n📚 Documentation:`)
      console.log(`   • GraphQL Playground: Open /graphql in browser\n`)
    })
  } catch (err) {
    console.error('❌ Error starting server:', err)
    process.exit(1)
  }
}

// Graceful Shutdown
const shutdown = () => {
  console.log('\n🛑 Shutting down gracefully...')
  if (server) {
    server.close(() => {
      console.log('✓ Server closed')
      process.exit(0)
    })
  } else {
    process.exit(0)
  }
}

process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)

start()
