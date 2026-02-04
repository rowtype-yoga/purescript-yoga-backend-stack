export const createProducerImpl = (kafka, opts) => kafka.producer(opts);

export const connectProducerImpl = (producer) => producer.connect();

export const sendImpl = (producer, record) => producer.send(record);

export const disconnectProducerImpl = (producer) => producer.disconnect();
