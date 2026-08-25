/** @type {import('@memberjunction/config').MJConfig} */
module.exports = {
  /**
   * MemberJunction v3.0 Minimal Distribution Configuration
   *
   * This config leverages the minimal configuration system where most settings
   * come from package defaults:
   * - Database settings → Environment variables (via config schema defaults)
   * - CodeGen settings → DEFAULT_CODEGEN_CONFIG (@memberjunction/codegen-lib)
   *
   * You only need to specify:
   * 1. Environment variables in .env file (database, auth)
   * 2. Deployment-specific settings (output paths, commands) - BELOW
   * 3. Any settings you want to override from the defaults
   */

  // ============================================================================
  // DEPLOYMENT-SPECIFIC CONFIGURATION (Required)
  // ============================================================================

  /**
   * Output paths for code generation
   * These are specific to this distribution's directory structure
   */
  entityPackageName: '@mj-biz-apps/common-entities',

  output: [
    { type: 'SQL', directory: './SQL Scripts/generated', appendOutputCode: true },
    {
      type: 'Angular',
      directory: './packages/Angular/src/lib/generated',
      options: [{ name: 'maxComponentsPerModule', value: 20 }],
    },
    { type: 'GraphQLServer', directory: './packages/Server/src/generated' },
    { type: 'ActionSubclasses', directory: './packages/Actions/src/generated' },
    { type: 'EntitySubclasses', directory: './packages/Entities/src/generated' },
    { type: 'DBSchemaJSON', directory: './Schema Files' },
  ],

  /**
   * Build commands to run after code generation
   * These are specific to this distribution's package structure
   */
  commands: [
    {
      workingDirectory: './packages/Entities',
      command: 'pnpm',
      args: ['run', 'build'],
      when: 'after',
    },
    {
      workingDirectory: './packages/Actions',
      command: 'pnpm',
      args: ['run', 'build'],
      when: 'after',
    },
    {
      workingDirectory: './packages/Server',
      command: 'pnpm',
      args: ['run', 'build'],
      when: 'after',
    },
    {
      workingDirectory: './packages/Angular',
      command: 'pnpm',
      args: ['run', 'build'],
      when: 'after',
    },
  ],

  // ============================================================================
  // OPTIONAL OVERRIDES
  // ============================================================================
  // Everything below this line is OPTIONAL. These settings have sensible defaults
  // in DEFAULT_SERVER_CONFIG and DEFAULT_CODEGEN_CONFIG.
  //
  // Uncomment and modify only if you need to override the defaults.
  // ============================================================================

  // ---------------------------------------------------------------------------
  // CodeGen Settings Overrides
  // ---------------------------------------------------------------------------
  // Default: [
  //   { name: 'mj_core_schema', value: '__mj' },
  //   { name: 'skip_database_generation', value: false },
  //   { name: 'recompile_mj_views', value: true },
  //   { name: 'auto_index_foreign_keys', value: true },
  // ]
  // settings: [
  //   { name: 'mj_core_schema', value: '__mj' },
  //   { name: 'skip_database_generation', value: false },
  //   { name: 'recompile_mj_views', value: true },
  //   { name: 'auto_index_foreign_keys', value: true },
  // ],

  // ---------------------------------------------------------------------------
  // Logging Overrides
  // ---------------------------------------------------------------------------
  // Default: { log: true, logFile: 'codegen.output.log', console: true }
  // logging: {
  //   log: true,
  //   logFile: 'codegen.output.log',
  //   console: true,
  // },

  // ---------------------------------------------------------------------------
  // New Entity Defaults Overrides
  // ---------------------------------------------------------------------------
  // Default v3.x settings for new entities
  testing: {
    checkModules: ['@mj-biz-apps/common-integration-tests'],
  },

  newEntityDefaults: {
    NameRulesBySchema: [
      { SchemaName: '${mj_core_schema}', EntityNamePrefix: 'MJ: ' },
      // BizApps family convention: prefix this app's entities so their MJ
      // entity names are globally unambiguous, e.g. 'MJ_BizApps_Common: People'.
      // Required before CodeGen on new tables (Activities) or they land unprefixed
      // and metadata/ lookups for 'MJ_BizApps_Common: Activity Types' miss.
      { SchemaName: '__mj_BizAppsCommon', EntityNamePrefix: 'MJ_BizApps_Common: ', EntityNameSuffix: '' },
      {
        SchemaName: 'Committees',
        EntityNamePrefix: 'Committees: ',
        EntityNameSuffix: '',
      },
    ],
  },

  // ---------------------------------------------------------------------------
  // Schema/Table Exclusions
  // ---------------------------------------------------------------------------
  // Default: excludeSchemas: ['sys', 'staging', '__mj']
  // Default: excludeTables: [{ schema: '%', table: 'sys%' }, { schema: '%', table: 'flyway_schema_history' }]
  //
  // Using defaults - Core entities (__mj schema) should not be modified by distributions.
  // Uncomment only if you need different exclusions than the defaults.
  //
  // The sibling app schemas are excluded for the same reason bizapps-orders excludes
  // common/accounting/tasks and bizapps-tasks excludes common: each app owns exactly its
  // own schema. Common is the base of the family so it has no dependencies to keep out —
  // but a database can host SEVERAL of these apps at once (a joined dev workspace, or any
  // host that installed more than one Open App). Without these entries CodeGen run from
  // this repo registers the siblings' tables as entities and writes their generated classes
  // into THIS repo's packages, which is silent and wrong. Listing consumers here is
  // slightly backwards, but naming a schema that is absent is inert, and the alternative
  // is a footgun that only fires on multi-app databases.
  excludeSchemas: [
    'sys', 'staging', 'dbo', '__mj', '__mj_UDT',
    '__mj_BizAppsOrders', '__mj_BizAppsAccounting', '__mj_BizAppsTasks',
    '__mj_BizAppsIssues', '__mj_BizAppsForms', '__mj_BizAppsATS', '__mj_BizAppsCaliber',
    '__mj_BizAppsCommittees', '__mj_BizAppsMarketing', '__mj_BizAppsSecureMessaging',
    '__mj_BizAppsSonar', 'Committees', 'Sonar',
  ],
  // excludeTables: [
  //   { schema: '%', table: 'sys%' },
  //   { schema: '%', table: 'flyway_schema_history' }
  // ],

  // ---------------------------------------------------------------------------
  // AI-Powered Advanced Generation Features
  // ---------------------------------------------------------------------------
  // Default v3.x: Several features enabled by default
  // advancedGeneration: {
  //   enableAdvancedGeneration: true,
  //   features: [
  //     { name: 'EntityNames', enabled: false },
  //     { name: 'DefaultInViewFields', enabled: true },
  //     { name: 'EntityDescriptions', enabled: false },
  //     { name: 'SmartFieldIdentification', enabled: true },
  //     { name: 'TransitiveJoinIntelligence', enabled: true },
  //     { name: 'FormLayoutGeneration', enabled: true },
  //     { name: 'ParseCheckConstraints', enabled: true },
  //   ],
  // },

  // ---------------------------------------------------------------------------
  // SQL Output (for migrations)
  // ---------------------------------------------------------------------------
  // Default v3.x: enabled: true, folderPath: './migrations/v3/'
  SQLOutput: {
    enabled: true,
    folderPath: './migrations/codegen/',
    appendToFile: false,
    convertCoreSchemaToFlywayMigrationFile: true,
    omitRecurringScriptsFromLog: false,
    schemaPlaceholders: [
      // Order matters: more-specific schemas must come first because
      // substitution is run sequentially with a greedy regex. If '__mj'
      // were listed first, it would also match the '__mj' prefix of
      // '__mj_BizAppsCommon', producing '${mjSchema}_BizAppsCommon'.
      { schema: '__mj_BizAppsCommon', placeholder: '${flyway:defaultSchema}' },
      { schema: '__mj', placeholder: '${mjSchema}' }
    ]
  },

  // ---------------------------------------------------------------------------
  // Force Regeneration Options
  // ---------------------------------------------------------------------------
  // Default: All false (only regenerate on schema changes)
  // forceRegeneration: {
  //   enabled: false,
  //   baseViews: false,
  //   spCreate: false,
  //   spUpdate: false,
  //   spDelete: false,
  //   allStoredProcedures: false,
  //   indexes: false,
  //   fullTextSearch: false,
  // },

  // ---------------------------------------------------------------------------
  // Database Connection Overrides
  // ---------------------------------------------------------------------------
  // These come from DEFAULT_SERVER_CONFIG with environment variable defaults
  // dbHost: process.env.DB_HOST ?? 'localhost',
  // dbPort: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 1433,
  // dbDatabase: process.env.DB_DATABASE,
  // dbUsername: process.env.DB_USERNAME,
  // dbPassword: process.env.DB_PASSWORD,
  // codeGenLogin: process.env.CODEGEN_DB_USERNAME,
  // codeGenPassword: process.env.CODEGEN_DB_PASSWORD,

  // ---------------------------------------------------------------------------
  // Server Settings Overrides
  // ---------------------------------------------------------------------------
  // These come from DEFAULT_SERVER_CONFIG
  // graphqlPort: process.env.GRAPHQL_PORT ?? 4000,
  // mjCoreSchema: process.env.MJ_CORE_SCHEMA ?? '__mj',
};
