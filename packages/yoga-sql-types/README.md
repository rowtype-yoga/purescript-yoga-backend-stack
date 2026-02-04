# yoga-sql-types

Type-safe SQL query builder and typed query support for PureScript SQL database bindings.

## Overview

This package provides:
- Type-level parameter tracking for SQL queries
- Type-safe query builders
- Result set parsing with type classes
- Table schema definitions
- Support for both generic SQL (`?` placeholders) and PostgreSQL (`$N` placeholders)

## Installation

```bash
spago install yoga-sql-types
```

## Usage

### Basic Typed Queries

```purescript
import Yoga.SQL.Types as SQL

-- Define a typed query with parameters
getUserQuery :: SQL.SQLQuery ( id :: Int )
getUserQuery = SQL.sql $
  "SELECT * FROM users WHERE id = " ^ SQL.int @"id"

-- Extract parameters in the correct order
params :: { id :: Int } -> Array SQL.SQLParameter
params = SQL.argsFor getUserQuery
```

### PostgreSQL-Style Parameters

```purescript
import Yoga.SQL.PostgresTypes as PGSQL

-- PostgreSQL uses $1, $2, etc. for parameters
getUserQuery :: PGSQL.SQLQuery ( id :: Int, name :: String )
getUserQuery = PGSQL.sql $
  "SELECT * FROM users WHERE id = " ^ PGSQL.int @"id" ^
  " AND name = " ^ PGSQL.str @"name"

-- Parameters are extracted in the correct order
params :: { id :: Int, name :: String } -> Array PGSQL.SQLParameter
params = PGSQL.argsFor getUserQuery
```

### Type-Safe Result Parsing

```purescript
import Yoga.SQL.Types (class FromResultArray, fromResultArray)

type User = { id :: Int, name :: String, email :: String }

-- Parse results from a query that returns (Int, String, String)
parseUser :: Array SQL.SQLResult -> Either String User
parseUser = fromResultArray \id name email -> { id, name, email }
```

### Table Schema Definition

```purescript
import Yoga.SQL.Types as SQL

usersTable :: SQL.Table
  ( id :: SQL.SQLColumn
  , name :: SQL.SQLColumn
  , email :: SQL.SQLColumn
  )
usersTable = SQL.table (SQL.TableName "users")
  { id: SQL.SQLColumn SQL.IntegerColumn [ SQL.PrimaryKey, SQL.NotNull ]
  , name: SQL.SQLColumn SQL.TextColumn [ SQL.NotNull ]
  , email: SQL.SQLColumn SQL.TextColumn [ SQL.Unique, SQL.NotNull ]
  }

-- Generate CREATE TABLE statement
createStatement :: SQL.CreateTableStatement
createStatement = SQL.createTable usersTable
```

## Type Classes

### `ToSQLParam`

Convert PureScript values to SQL parameters:

```purescript
class ToSQLParam a where
  toSQLParam :: a -> SQLParameter
```

Instances provided for:
- `Int`, `String`, `Number`, `Boolean`
- `Array a`, `NonEmptyArray a`
- `Maybe a`
- Any `Newtype` wrapper

### `SQLFromForeign`

Parse SQL results into PureScript values:

```purescript
class SQLFromForeign a where
  fromSQLResultImpl :: Foreign -> ExceptT (NonEmptyList ForeignError) Identity a
```

### `FromResultArray`

Parse multiple columns from a result row:

```purescript
class FromResultArray fn a | fn -> a where
  fromResultArray :: fn -> Array SQLResult -> Either String a
```

## Query Builder API

### Building Queries

- `sql` - Create a query from a builder
- `arg @type @name` - Add a typed parameter
- `int @name` - Add an Int parameter
- `str @name` - Add a String parameter
- `bool @name` - Add a Boolean parameter
- `num @name` - Add a Number parameter
- `nonArg` - Add a literal SQL string
- `^` - Compose builders (infixl 8)

### Example

```purescript
searchQuery :: SQL.SQLQuery ( minAge :: Int, maxAge :: Int, city :: String )
searchQuery = SQL.sql $
  "SELECT * FROM users WHERE age >= " ^ SQL.int @"minAge" ^
  " AND age <= " ^ SQL.int @"maxAge" ^
  " AND city = " ^ SQL.str @"city"
```

## Differences Between Generic and PostgreSQL Types

### Generic SQL (`Yoga.SQL.Types`)
- Uses `?` for parameter placeholders
- Parameters extracted in order they appear
- Compatible with SQLite, MySQL, and other databases

### PostgreSQL (`Yoga.SQL.PostgresTypes`)
- Uses `$1`, `$2`, etc. for parameter placeholders
- Parameters numbered automatically
- Optimised for PostgreSQL's parameter format

## Integration with Database Bindings

This package is used by:
- `yoga-postgres` - PostgreSQL bindings
- `yoga-scylladb` - ScyllaDB/Cassandra bindings
- `yoga-sqlite` - SQLite bindings
- `yoga-bun-sqlite` - Bun SQLite bindings
- `yoga-node-sqlite` - Node SQLite bindings

## Related Packages

- [yoga-postgres](../yoga-postgres) - PostgreSQL client with typed queries
- [yoga-scylladb](../yoga-scylladb) - ScyllaDB client with typed queries
- [yoga-sqlite](../yoga-sqlite) - SQLite client with typed queries
- [yoga-json](https://github.com/rowtype-yoga/purescript-yoga-json) - JSON library used internally

## License

MIT
