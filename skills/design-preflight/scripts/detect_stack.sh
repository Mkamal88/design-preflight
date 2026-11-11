#!/usr/bin/env bash
# Prints a short summary of the technology stack in a repository.
# Read-only: it only lists and searches files.
# Usage: detect_stack.sh [repo-root]
# Works with the bash 3.2 that ships with macOS.

set -euo pipefail

root="${1:-.}"
if [ ! -d "$root" ]; then
  echo "error: not a directory: $root" >&2
  exit 1
fi
cd "$root"

# Folder depth to scan; deep enough for most monorepos.
MAX_DEPTH=4

# Every file up to MAX_DEPTH, skipping dependency and build folders.
files="$(find . -maxdepth "$MAX_DEPTH" \
  \( -name node_modules -o -name .git -o -name vendor -o -name dist -o -name build \
     -o -name .venv -o -name venv -o -name target -o -name .next -o -name coverage \) -prune \
  -o -type f -print 2>/dev/null || true)"

found=""

add() { # category label
  found="${found}${1}|${2}
"
}

matching_files() { # file-regex
  printf '%s\n' "$files" | grep -E "$1" || true
}

file_exists() { # file-regex
  [ -n "$(matching_files "$1")" ]
}

file_contains() { # content-regex file-regex
  local list f
  list="$(matching_files "$2")"
  [ -n "$list" ] || return 1
  while IFS= read -r f; do
    if [ -n "$f" ] && grep -Eqs -- "$1" "$f"; then
      return 0
    fi
  done <<EOF
$list
EOF
  return 1
}

check() { # category label content-regex file-regex
  if file_contains "$3" "$4"; then
    add "$1" "$2"
  fi
}

NODE='(^|/)package\.json$'
PY='(^|/)(requirements[^/]*\.txt|pyproject\.toml|Pipfile|setup\.py)$'
RUBY='(^|/)Gemfile$'
GO='(^|/)go\.mod$'
JVM='(^|/)(pom\.xml|build\.gradle(\.kts)?)$'
DOTNET='\.csproj$'
PHP='(^|/)composer\.json$'
RUST='(^|/)Cargo\.toml$'
COMPOSE='(^|/)(docker-)?compose[^/]*\.ya?ml$'
PRISMA='\.prisma$'

# Languages
file_exists "$NODE" && add "Language" "JavaScript/Node.js"
file_exists '(^|/)tsconfig[^/]*\.json$' && add "Language" "TypeScript"
file_exists "$PY" && add "Language" "Python"
file_exists "$RUBY" && add "Language" "Ruby"
file_exists "$GO" && add "Language" "Go"
file_exists "$JVM" && add "Language" "Java/Kotlin"
file_exists "$DOTNET" && add "Language" "C#/.NET"
file_exists "$PHP" && add "Language" "PHP"
file_exists "$RUST" && add "Language" "Rust"

# Frameworks
check "Framework" "Express" '"express"' "$NODE"
check "Framework" "Fastify" '"fastify"' "$NODE"
check "Framework" "NestJS" '"@nestjs/core"' "$NODE"
check "Framework" "Koa" '"koa"' "$NODE"
check "Framework" "Hono" '"hono"' "$NODE"
check "Framework" "Next.js" '"next"' "$NODE"
check "Framework" "React" '"react"' "$NODE"
check "Framework" "Vue" '"vue"' "$NODE"
check "Framework" "Angular" '"@angular/core"' "$NODE"
check "Framework" "Svelte" '"svelte"' "$NODE"
check "Framework" "Vite" '"vite"' "$NODE"
check "Framework" "React Native" '"react-native"' "$NODE"
check "Framework" "GraphQL" '"graphql"' "$NODE"
check "Framework" "Django" '[Dd]jango' "$PY"
check "Framework" "FastAPI" '[Ff]ast[Aa][Pp][Ii]' "$PY"
check "Framework" "Flask" '[Ff]lask' "$PY"
check "Framework" "Rails" "rails" "$RUBY"
check "Framework" "Gin" 'gin-gonic/gin' "$GO"
check "Framework" "Echo" 'labstack/echo' "$GO"
check "Framework" "Fiber" 'gofiber/fiber' "$GO"
check "Framework" "Spring Boot" 'spring-boot' "$JVM"
check "Framework" "ASP.NET Core" 'Microsoft\.AspNetCore' "$DOTNET"
check "Framework" "Laravel" 'laravel/framework' "$PHP"
check "Framework" "Symfony" 'symfony/' "$PHP"
check "Framework" "Axum" 'axum' "$RUST"
check "Framework" "Actix" 'actix-web' "$RUST"

# Data layer
check "Data layer" "Prisma" '"(@prisma/client|prisma)"' "$NODE"
check "Data layer" "TypeORM" '"typeorm"' "$NODE"
check "Data layer" "Sequelize" '"sequelize"' "$NODE"
check "Data layer" "Drizzle" '"drizzle-orm"' "$NODE"
check "Data layer" "Knex" '"knex"' "$NODE"
check "Data layer" "Mongoose" '"mongoose"' "$NODE"
check "Data layer" "SQLAlchemy" '[Ss][Qq][Ll][Aa]lchemy' "$PY"
check "Data layer" "Alembic" 'alembic' "$PY"
check "Data layer" "ActiveRecord" 'rails|activerecord' "$RUBY"
check "Data layer" "GORM" 'gorm\.io' "$GO"
check "Data layer" "sqlx (Go)" 'jmoiron/sqlx' "$GO"
check "Data layer" "Hibernate/JPA" 'hibernate|spring-boot-starter-data-jpa' "$JVM"
check "Data layer" "Flyway" 'flyway' "$JVM"
check "Data layer" "Liquibase" 'liquibase' "$JVM"
check "Data layer" "EF Core" 'EntityFrameworkCore' "$DOTNET"
check "Data layer" "Doctrine" 'doctrine/' "$PHP"
check "Data layer" "Diesel" 'diesel' "$RUST"
check "Data layer" "sqlx (Rust)" 'sqlx' "$RUST"

# Databases
check "Database" "PostgreSQL" 'provider *= *"postgresql"' "$PRISMA"
check "Database" "MySQL" 'provider *= *"mysql"' "$PRISMA"
check "Database" "SQLite" 'provider *= *"sqlite"' "$PRISMA"
check "Database" "MongoDB" 'provider *= *"mongodb"' "$PRISMA"
check "Database" "PostgreSQL" 'image: *[^ ]*postgres' "$COMPOSE"
check "Database" "MySQL" 'image: *[^ ]*(mysql|mariadb)' "$COMPOSE"
check "Database" "MongoDB" 'image: *[^ ]*mongo' "$COMPOSE"
check "Database" "PostgreSQL" '"(pg|postgres)"' "$NODE"
check "Database" "MySQL" '"mysql2?"' "$NODE"
check "Database" "PostgreSQL" 'psycopg|asyncpg' "$PY"
check "Database" "PostgreSQL" "gem ['\"]pg['\"]" "$RUBY"
check "Database" "PostgreSQL" 'jackc/pgx|lib/pq' "$GO"
check "Database" "PostgreSQL" 'postgresql' "$JVM"
check "Database" "PostgreSQL" 'Npgsql' "$DOTNET"

# Cache
check "Cache" "Redis" '"(redis|ioredis)"' "$NODE"
check "Cache" "Redis" 'redis' "$PY"
check "Cache" "Redis" 'redis' "$RUBY"
check "Cache" "Redis" 'redis' "$GO"
check "Cache" "Redis" 'image: *[^ ]*(redis|valkey)' "$COMPOSE"
check "Cache" "Memcached" 'image: *[^ ]*memcached' "$COMPOSE"

# Background work
check "Background work" "BullMQ/Bull" '"(bullmq|bull)"' "$NODE"
check "Background work" "pg-boss" '"pg-boss"' "$NODE"
check "Background work" "Graphile Worker" '"graphile-worker"' "$NODE"
check "Background work" "AWS SQS" '"@aws-sdk/client-sqs"' "$NODE"
check "Background work" "Kafka" '"kafkajs"' "$NODE"
check "Background work" "RabbitMQ" '"amqplib"' "$NODE"
check "Background work" "Celery" 'celery' "$PY"
check "Background work" "RQ" '(^|[^a-z])rq([^a-z]|$)' "$PY"
check "Background work" "Sidekiq" 'sidekiq' "$RUBY"
check "Background work" "Kafka" 'kafka' "$JVM"
check "Background work" "RabbitMQ" 'image: *[^ ]*rabbitmq' "$COMPOSE"
check "Background work" "Kafka" 'image: *[^ ]*kafka' "$COMPOSE"

# Search
check "Search" "Elasticsearch/OpenSearch" 'image: *[^ ]*(elasticsearch|opensearch)' "$COMPOSE"
check "Search" "Meilisearch" 'image: *[^ ]*meilisearch' "$COMPOSE"

# Infrastructure
file_exists '(^|/)Dockerfile[^/]*$' && add "Infrastructure" "Docker"
file_exists "$COMPOSE" && add "Infrastructure" "Docker Compose"
file_exists '\.tf$' && add "Infrastructure" "Terraform"
file_exists '(^|/)cdk\.json$' && add "Infrastructure" "AWS CDK"
file_exists '(^|/)serverless\.ya?ml$' && add "Infrastructure" "Serverless Framework"
file_exists '(^|/)(template|samconfig)\.(ya?ml|toml)$' && add "Infrastructure" "AWS SAM (maybe)"
file_exists '(^|/)(Chart\.yaml|kustomization\.ya?ml)$' && add "Infrastructure" "Kubernetes"
file_exists '(^|/)\.github/workflows/' && add "Infrastructure" "GitHub Actions"
file_exists '(^|/)\.gitlab-ci\.yml$' && add "Infrastructure" "GitLab CI"

# Tests
check "Tests" "Vitest" '"vitest"' "$NODE"
check "Tests" "Jest" '"jest"' "$NODE"
check "Tests" "Mocha" '"mocha"' "$NODE"
check "Tests" "node:test" '(node|tsx)[^"]* --test' "$NODE"
check "Tests" "Playwright" '"@playwright/test"' "$NODE"
check "Tests" "Cypress" '"cypress"' "$NODE"
check "Tests" "pytest" 'pytest' "$PY"
check "Tests" "RSpec" 'rspec' "$RUBY"
check "Tests" "JUnit" 'junit' "$JVM"

# Project context the review should read
for doc in AGENTS.md CLAUDE.md .design-preflight.md CONTRIBUTING.md; do
  file_exists "(^|/)$(printf '%s' "$doc" | sed 's/\./\\./g')$" && add "Project context" "$doc"
done
file_exists '(^|/)(docs/)?(adr|decisions)/' && add "Project context" "decision records"

print_category() { # category
  local items
  items="$(printf '%s' "$found" | grep -F "$1|" | cut -d'|' -f2 | sort -u | paste -sd, - | sed 's/,/, /g' || true)"
  printf '%-16s %s\n' "$1:" "${items:-none found}"
}

echo "Stack summary for: $(pwd)"
echo
for category in "Language" "Framework" "Data layer" "Database" "Cache" "Background work" \
                "Search" "Infrastructure" "Tests" "Project context"; do
  print_category "$category"
done

# Where to look next
echo
echo "Schema and migration locations (first 10):"
paths="$(matching_files '(\.prisma$|(^|/)migrations?/|(^|/)db/(schema\.rb|structure\.sql)$|(^|/)alembic/|(^|/)db/migrate/|\.entity\.ts$|(^|/)models\.py$)' \
  | sed -E 's#/[^/]*$##' | sort -u | head -n 10)"
if [ -n "$paths" ]; then
  printf '%s\n' "$paths" | sed 's/^/  /'
else
  echo "  none found"
fi

manifest_count="$(matching_files "$NODE" | grep -c . || true)"
if [ "${manifest_count:-0}" -gt 1 ]; then
  echo
  echo "Note: $manifest_count package.json files found; this may be a monorepo."
fi
