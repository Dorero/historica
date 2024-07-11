MeiliSearch::Rails.configuration = {
  meilisearch_url: ENV.fetch('MEILISEARCH_HOST', 'http://localhost:7700'),
  meilisearch_api_key: ENV.fetch('MEILISEARCH_API_KEY', 'J2LUmlx8aLQ1fW7ebeD7xpt9hpblRfO4UT4x30uAe1Q')
}
