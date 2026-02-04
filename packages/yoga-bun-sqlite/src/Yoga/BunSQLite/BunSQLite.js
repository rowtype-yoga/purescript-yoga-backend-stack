import { Database } from 'bun:sqlite';

// Open a database connection
export const openImpl = (path) => {
  return new Database(path);
};

// Close a database connection
export const closeImpl = (db) => {
  db.close();
};

// Run SQL directly (for DDL/DML)
export const runImpl = (sql, db) => {
  db.run(sql);
};

// Query directly (for simple queries)
export const queryImpl = (sql, db) => {
  return db.query(sql).all();
};

// Prepare a statement
export const prepareImpl = (sql, db) => {
  return db.prepare(sql);
};

// Run a prepared statement
export const stmtRunImpl = (params, stmt) => {
  stmt.run(...params);
};

// Get a single row from a prepared statement
export const stmtGetImpl = (params, stmt) => {
  const row = stmt.get(...params);
  return row || null;
};

// Get all rows from a prepared statement
export const stmtAllImpl = (params, stmt) => {
  return stmt.all(...params);
};

// Finalize a prepared statement
export const stmtFinalizeImpl = (stmt) => {
  stmt.finalize();
};
