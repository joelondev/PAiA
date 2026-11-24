/**
 * PAiA: third-party product analytics are removed from appliance builds.
 * Prompts, documents and usage never leave the unit; device health is reported
 * only to the PAiA Update Service by the update agent.
 *
 * Kept as a component so existing layout code does not need to change.
 */
export function AnalyticProvider() {
  return null
}
