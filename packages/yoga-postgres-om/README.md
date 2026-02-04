# yoga-postgres-om

Om-wrapped PostgreSQL operations for PureScript.

## Installation

```bash
spago install yoga-postgres-om yoga-om-core yoga-om-layer
```

## Usage

```purescript
import Yoga.Postgres.Om as PG
import Yoga.Postgres.OmLayer as PGLayer

main = launchAff_ do
  runOm (PGLayer.live config) do
    rows <- PG.query "SELECT * FROM users" []
    -- Use PostgreSQL operations without manually passing connection
```

See [yoga-postgres](../yoga-postgres) for raw bindings.

## License

MIT
