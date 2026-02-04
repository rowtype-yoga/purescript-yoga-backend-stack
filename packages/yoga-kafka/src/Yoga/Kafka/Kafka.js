import { Kafka } from 'kafkajs';

export const kafkaImpl = (config) => new Kafka(config);
