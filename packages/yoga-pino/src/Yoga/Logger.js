/**
 * Unified logger interface
 * Wraps Pino, OTEL, or Hybrid loggers with the same API
 */

export const logInfoImpl = (logger, message, context) => {
  logger.info(message, context);
};

export const logDebugImpl = (logger, message, context) => {
  logger.debug(message, context);
};

export const logWarnImpl = (logger, message, context) => {
  logger.warn(message, context);
};

export const logErrorImpl = (logger, message, context) => {
  logger.error(message, context);
};
