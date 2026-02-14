## User MCP Servers

Custom MCP servers configured for this project.

### microsoft-learn

**Source:** `mcp_servers.json`
**Purpose:** Access official Microsoft and Azure PowerShell documentation
**Status:** ✅ All tools working

Microsoft Learn MCP Server provides structured access to official Microsoft documentation, code samples, and learning resources. Ideal for PowerShell module development questions, Azure integration, and finding official code examples.

**Available Tools:**

| Tool | Status | Description |
|------|--------|-------------|
| `microsoft_docs_search` | ✅ | Search Microsoft Learn documentation, returns 10 results |
| `microsoft_code_sample_search` | ✅ | Search for PowerShell code snippets and examples |
| `microsoft_docs_fetch` | ✅ | Fetch full documentation pages as markdown |

**Workflow:**

1. **Search first** - `microsoft_docs_search` for quick overview
2. **Get code examples** - `microsoft_code_sample_search` for snippets
3. **Fetch details** - `microsoft_docs_fetch` for complete documentation

**Example Usage:**

```bash
# Search for PowerShell module documentation
mcp-cli call microsoft-learn microsoft_docs_search '{"query": "PowerShell module manifest"}'

# Find code examples for functions
mcp-cli call microsoft-learn microsoft_code_sample_search '{"query": "PowerShell function", "language": "powershell"}'

# Fetch full documentation page
mcp-cli call microsoft-learn microsoft_docs_fetch '{"url": "https://learn.microsoft.com/powershell/..."}'
```

**When to Use:**

- Looking up PowerShell cmdlet reference
- Finding Azure PowerShell examples
- Understanding module structure and best practices
- Researching Pester testing patterns
- Getting official Microsoft code samples
