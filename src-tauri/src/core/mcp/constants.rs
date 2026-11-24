// Default MCP runtime settings
pub const DEFAULT_MCP_TOOL_CALL_TIMEOUT_SECS: u64 = 30;
pub const DEFAULT_MCP_BASE_RESTART_DELAY_MS: u64 = 1000; // Start with 1 second
pub const DEFAULT_MCP_MAX_RESTART_DELAY_MS: u64 = 30000; // Cap at 30 seconds
pub const DEFAULT_MCP_BACKOFF_MULTIPLIER: f64 = 2.0; // Double the delay each time

/// PAiA: no MCP servers ship enabled by default. Jan's defaults installed
/// packages from npm/PyPI at runtime (npx/uvx) and enabled a third-party search
/// service (mcp.exa.ai). Approved tool servers will ship pre-bundled and signed
/// inside PAiA releases instead.
pub const DEFAULT_MCP_CONFIG: &str = r#"{
  "mcpServers": {},
  "mcpSettings": {
    "toolCallTimeoutSeconds": 30,
    "baseRestartDelayMs": 1000,
    "maxRestartDelayMs": 30000,
    "backoffMultiplier": 2.0,
    "enableSmartToolRouting": true,
    "useLightweightRouterModel": false,
    "routerModelProvider": "",
    "routerModelId": ""
  }
}"#;
