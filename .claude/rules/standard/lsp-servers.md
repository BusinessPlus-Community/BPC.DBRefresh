## LSP Servers - Code Intelligence

**Rule:** Use LSP operations proactively for accurate code understanding.

**Available:** Python (Pyright), TypeScript

### Operations

| Operation | Use Case | Support |
|-----------|----------|---------|
| `goToDefinition` | Find where symbol is defined | ✅ Both |
| `findReferences` | Find all usages of a symbol | ✅ Both |
| `hover` | Get type info and documentation | ✅ Both |
| `documentSymbol` | List all symbols in a file | ✅ Both |
| `workspaceSymbol` | Search symbols across codebase | TS only |
| `prepareCallHierarchy` | Get call hierarchy item at position | ✅ Python |
| `incomingCalls` | Find callers of a function | ✅ Python |
| `outgoingCalls` | Find functions called by a function | ✅ Python |

### Required Parameters

All operations require: `filePath`, `line` (1-based), `character` (1-based)

### When to Use LSP

**Prefer LSP over grep/search for:**
- Understanding function signatures and types
- Tracing call chains and dependencies
- Finding all references before refactoring
- Navigating to definitions instead of searching

**Use before:**
- Modifying functions (check callers with `findReferences`)
- Refactoring (understand hierarchy with `incomingCalls`/`outgoingCalls`)
- Reading unfamiliar code (`hover` for types, `documentSymbol` for structure)

### Examples

```
# Get function signature and docs
LSP(hover, "installer/cli.py", 31, 5)

# Find all usages before renaming
LSP(findReferences, "installer/context.py", 15, 7)

# Understand what a function calls
LSP(outgoingCalls, "installer/cli.py", 31, 5)

# List all functions in a file
LSP(documentSymbol, "installer/ui.py", 1, 1)
```

**LSP provides compiler-accurate results. Use it.**
