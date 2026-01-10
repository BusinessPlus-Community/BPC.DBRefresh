## TypeScript Development Standards

**Standards:** Detect package manager | Strict types | No `any` | Self-documenting code

### Package Manager - DETECT FIRST, THEN USE CONSISTENTLY

**MANDATORY: Detect and use the project's existing package manager. NEVER mix package managers.**

Check the project root for lock files:
- `bun.lockb` → use **bun**
- `pnpm-lock.yaml` → use **pnpm**
- `yarn.lock` → use **yarn**
- `package-lock.json` → use **npm**

If no lock file exists, check `packageManager` field in `package.json`, or default to npm.

**If you're about to run `npm` but see `yarn.lock`:** STOP. Use yarn instead.

**Why this matters:** Mixing package managers corrupts lock files and breaks reproducible builds.

### Type Safety

**Explicit return types on all exported functions:**
```typescript
export function processOrder(orderId: string, userId: number): Order { ... }
export async function fetchUser(id: string): Promise<User> { ... }
```

**Interfaces for objects, types for unions:**
```typescript
interface User { id: string; email: string; }
type Status = 'pending' | 'active' | 'suspended';
```

**Avoid `any` - use `unknown` instead:**
```typescript
// BAD: function parse(data: any) { ... }
// GOOD: function parse(data: unknown) { ... }
```

**If you're about to type `any`:** STOP. Use `unknown`, a specific type, or a generic instead.

### Code Style

**Self-documenting code. Minimize comments.**
```typescript
// BAD: if (u.r === 'admin')
// GOOD: if (user.isAdmin())
```

**One-line JSDoc for exports:**
```typescript
/** Calculate discounted price by applying rate. */
export function calculateDiscount(price: number, rate: number): number { ... }
```

**Import order:** Node built-ins → External packages → Internal modules → Relative imports

### Verification Checklist

Before completing TypeScript work, **always run** (using detected package manager):

1. **Type check:** `tsc --noEmit` or project's `typecheck` script
2. **Lint:** `eslint . --fix` or project's `lint` script
3. **Format:** `prettier --write .` or project's `format` script
4. **Tests:** Project's `test` script

**⚠️ BLOCKERS - Do NOT mark work complete if:**
- Type checking fails (`tsc --noEmit` has errors)
- Lint errors exist (warnings OK, errors are blockers)
- Tests fail

**If `tsc --noEmit` shows errors:** STOP. Fix type errors before proceeding.

Verify:
- [ ] All commands pass without errors
- [ ] Explicit return types on exports
- [ ] No `any` types (use `unknown` instead)
- [ ] Correct lock file committed

### Quick Reference

| Task         | npm                  | yarn              | pnpm              | bun              |
| ------------ | -------------------- | ----------------- | ----------------- | ---------------- |
| Install all  | `npm install`        | `yarn`            | `pnpm install`    | `bun install`    |
| Add package  | `npm install pkg`    | `yarn add pkg`    | `pnpm add pkg`    | `bun add pkg`    |
| Add dev dep  | `npm install -D pkg` | `yarn add -D pkg` | `pnpm add -D pkg` | `bun add -D pkg` |
| Run script   | `npm run script`     | `yarn script`     | `pnpm script`     | `bun script`     |
| Type check   | `npx tsc --noEmit`   | `yarn tsc --noEmit` | `pnpm tsc --noEmit` | `bunx tsc --noEmit` |
