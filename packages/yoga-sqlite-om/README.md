# yoga-sqlite-om

Om-wrapped SQLite operations for PureScript.

## Installation

```bash
spago install yoga-sqlite-om yoga-om-core yoga-om-layer
```

## Usage

```purescript
import Yoga.SQLite.OmLayer as SQLiteLayer
import Yoga.Om (runOm)

main = launchAff_ do
  runOm (SQLiteLayer.live { path: ":memory:" }) do
    -- Use SQLite operations with implicit connection from environment
    pure unit
```

See [yoga-sqlite](../yoga-sqlite) for raw bindings.

## License

MIT
