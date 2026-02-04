import { DatabaseSync } from 'node:sqlite';

// Open a database connection
export const openImpl = (path) => {
  return new DatabaseSync(path);
};

// Close a database connection
export const closeImpl = (db) => {
  db.close();
};

// Execute SQL (for DDL/DML without results)
export const execImpl = (sql, db) => {
  db.exec(sql);
};

// Prepare a statement
export const prepareImpl = (sql, db) => {
  return db.prepare(sql);
};

// Run a statement (INSERT/UPDATE/DELETE)
export const runImpl = (params, stmt) => {
  stmt.run(...params);
};

// Get a single row
export const getImpl = (params, stmt) => {
  const row = stmt.get(...params);
  return row || null;
};

// Get all rows
export const allImpl = (params, stmt) => {
  return stmt.all(...params);
};

// Finalize a statement
export const finalizeImpl = (stmt) => {
  // Note: Node's built-in SQLite doesn't have explicit finalize,
  // but we provide this for API compatibility
};
