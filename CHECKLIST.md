# API Migration Checklist

## Phase 1: REST API (✅ COMPLETE)

### Files Deleted (8)
- ✅ `src/index.ts` - Entry point
- ✅ `src/interface/rest/itemsRouter.ts` - Express router
- ✅ `src/interface/rest/ItemsController.ts` - Express handlers
- ✅ `src/interface/rest/util/route.ts` - Route utilities
- ✅ `src/core/services/ItemService.ts` - Service layer
- ✅ `src/core/errors/AppError.ts` - Error handling
- ✅ `src/core/dto/item.dto.ts` - DTOs
- ✅ `src/middleware/errorHandler.ts` - Express middleware

### Files Created (7)
- ✅ `src/index.res` - Bun.serve entry point
- ✅ `src/http/BunServer.res` - FFI bindings
- ✅ `src/interface/rest/Router.res` - URL routing
- ✅ `src/interface/rest/ItemsController.res` - Request handlers
- ✅ `src/core/types/Item.res` - Entity types
- ✅ `src/core/errors/AppError.res` - Error variants
- ✅ `src/core/schemas/Schemas.res` - Validation schemas
- ✅ `src/core/services/ItemService.res` - Service with DI

### Configuration
- ✅ `rescript.json` - ReScript compiler config
- ✅ `package.json` - Updated dependencies
- ✅ `MIGRATION.md` - Documentation

### Endpoints Implemented
- ✅ `GET /items` - List all items
- ✅ `GET /items/:id` - Get item by ID
- ✅ `POST /items` - Create item
- ✅ `PATCH /items/:id` - Update item
- ✅ `DELETE /items/:id` - Delete item

### Design Patterns
- ✅ **Polymorphic handlers**: `type handler = request => promise<response>`
- ✅ **Inline parsing**: No middleware pipeline
- ✅ **Centralized schemas**: Single source of truth for validation
- ✅ **Error variants**: All errors as `AppError.t` variants
- ✅ **Dependency injection**: Services accept deps, allow testing

---

## Phase 2: Database Layer (TODO)

### Steps
- [ ] Choose database: Bun SQLite vs PostgreSQL
- [ ] Create FFI bindings for database
- [ ] Migrate TypeORM entities to ReScript types
- [ ] Implement `ItemService.deps` functions
- [ ] Populate queries (list, get, create, update, delete)
- [ ] Test with real database

### Remaining TypeScript Files (ORM layer)
- `src/orm/types.ts` - TypeORM metadata
- `src/orm/index.ts` - TypeORM initialization
- `src/orm/dialect.ts` - Database dialect config
- `src/core/entities.ts` - Entity definitions
- `src/orm/QueryBuilder.ts` - Query builder
- `src/data-source/index.ts` - AppDataSource
- `src/index.ts` - Main entry (already deleted)

---

## Phase 3: Testing (TODO)

### Unit Tests
- [ ] Mock `ItemService.deps` for controller tests
- [ ] Test validation schemas
- [ ] Test error handling paths

### Integration Tests
- [ ] Test full request → response flow
- [ ] Test database persistence
- [ ] Test error scenarios

### CI/CD
- [ ] Add GitHub Actions workflow
- [ ] Format check: `rescript format -all -check`
- [ ] Build: `rescript build`
- [ ] Test: Run test suite

---

## Phase 4: Monitoring & Deployment (TODO)

### Observability
- [ ] Structured logging
- [ ] Error tracking (Sentry)
- [ ] Performance monitoring

### Deployment
- [ ] Build production bundle
- [ ] Docker containerization
- [ ] Deploy to hosting (Vercel, Railway, etc.)

---

## Summary

**Current Status**: API layer fully migrated from Express + TypeScript to Bun.serve + ReScript

**Dependencies**:
- ✅ Removed: Express (15+ transitive deps)
- ✅ Kept: rescript-schema (validation only)
- ✅ Total: 1 external dependency (minimal)

**Next Priority**: Database layer migration (Phase 2)
