// FFI for Pino Logger
import pino from 'pino';

export const createLogger = (options) => () => {
  return pino(options);
};

export const infoImpl = (logger, msg) => () => {
  logger.info(msg);
};

export const debugImpl = (logger, msg) => () => {
  logger.debug(msg);
};

export const warnImpl = (logger, msg) => () => {
  logger.warn(msg);
};

export const errorImpl = (logger, msg) => () => {
  logger.error(msg);
};

export const infoWithImpl = (logger, obj) => () => {
  logger.info(obj, obj.msg);
};

export const debugWithImpl = (logger, obj) => () => {
  logger.debug(obj, obj.msg);
};

export const warnWithImpl = (logger, obj) => () => {
  logger.warn(obj, obj.msg);
};

export const errorWithImpl = (logger, obj) => () => {
  logger.error(obj, obj.msg);
};

// New context-based logging: message + context object
export const infoWithContextImpl = (logger, msg, context) => () => {
  logger.info(context, msg);
};

export const debugWithContextImpl = (logger, msg, context) => () => {
  logger.debug(context, msg);
};

export const warnWithContextImpl = (logger, msg, context) => () => {
  logger.warn(context, msg);
};

export const errorWithContextImpl = (logger, msg, context) => () => {
  logger.error(context, msg);
};
