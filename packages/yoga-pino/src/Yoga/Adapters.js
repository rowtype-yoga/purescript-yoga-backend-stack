import pino from 'pino';
import { logs } from '@opentelemetry/api-logs';
import { SeverityNumber } from '@opentelemetry/api-logs';

// Helper functions (inlined from PinoOtel.js)
const getOtelLoggerImpl = (name) => {
  const loggerProvider = logs.getLoggerProvider();
  return loggerProvider.getLogger(name, '1.0.0');
};

const pinoLevelToSeverity = (level) => {
  switch (level) {
    case 'trace': return SeverityNumber.TRACE;
    case 'debug': return SeverityNumber.DEBUG;
    case 'info': return SeverityNumber.INFO;
    case 'warn': return SeverityNumber.WARN;
    case 'error': return SeverityNumber.ERROR;
    case 'fatal': return SeverityNumber.FATAL;
    default: return SeverityNumber.INFO;
  }
};

const emitOtelLogImpl = (otelLogger, level, message, context) => {
  const severityNumber = pinoLevelToSeverity(level);
  const severityText = level.toUpperCase();

  otelLogger.emit({
    severityNumber,
    severityText,
    body: message,
    attributes: context,
    timestamp: Date.now(),
  });
};

/**
 * Wrap Pino logger to match our unified Logger interface
 */
export const wrapPinoLoggerImpl = (pinoLogger) => {
  return {
    info: (message, context) => pinoLogger.info(context, message),
    debug: (message, context) => pinoLogger.debug(context, message),
    warn: (message, context) => pinoLogger.warn(context, message),
    error: (message, context) => pinoLogger.error(context, message),
  };
};

/**
 * Create a Pino-only logger (local dev)
 */
export const createPinoLoggerImpl = () => {
  const pinoLogger = pino();
  return wrapPinoLoggerImpl(pinoLogger);
};

/**
 * Create an OTEL-only logger (production without local logs)
 */
export const createOtelLoggerImpl = (name) => {
  const otelLogger = getOtelLoggerImpl(name);

  return {
    info: (message, context) => emitOtelLogImpl(otelLogger, 'info', message, context),
    debug: (message, context) => emitOtelLogImpl(otelLogger, 'debug', message, context),
    warn: (message, context) => emitOtelLogImpl(otelLogger, 'warn', message, context),
    error: (message, context) => emitOtelLogImpl(otelLogger, 'error', message, context),
  };
};
