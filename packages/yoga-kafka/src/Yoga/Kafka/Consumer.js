export const createConsumerImpl = (kafka, opts) => kafka.consumer(opts);

export const connectConsumerImpl = (consumer) => consumer.connect();

export const subscribeImpl = (consumer, opts) => consumer.subscribe(opts);

// Transform user options to match KafkaJS expectations
export const runImpl = (consumer, opts, transformKey, promiseToAff, affToPromise) => {
  const wrappedOpts = { ...opts };
  
  // Handle eachBatch if present - transform the batch and wrap the handler
  if (opts.eachBatch) {
    const userHandler = opts.eachBatch;
    
    wrappedOpts.eachBatch = async (payload) => {
      // 1. Transform message keys in-place (Nullable -> Maybe)
      for (const msg of payload.batch.messages) {
        msg.key = transformKey(msg.key);
      }
      
      // 2. Transform heartbeat in-place: Effect (Promise Unit) -> Aff Unit
      payload.heartbeat = promiseToAff(payload.heartbeat);
      
      // 3. Flatten structure - move batch fields to top level and expose all utility functions
      const flatPayload = {
        topic: payload.batch.topic,
        partition: payload.batch.partition,
        highWatermark: payload.batch.highWatermark,  // Last committed offset for lag calculation
        messages: payload.batch.messages,
        resolveOffset: (offset) => payload.resolveOffset(offset),  // Mark message as processed (fire-and-forget)
        heartbeat: payload.heartbeat,  // Already converted to Aff Unit
        commitOffsetsIfNecessary: () => payload.commitOffsetsIfNecessary(),  // Manual offset commit
        uncommittedOffsets: () => payload.uncommittedOffsets(),  // Get uncommitted offsets
        isRunning: () => payload.isRunning(),  // Check if running
        isStale: () => payload.isStale(),  // Check if batch is stale
        pause: () => payload.pause()  // Pause partition (returns resume function)
      };
      
      // 4. Call user handler (Batch -> Aff Unit) and convert result to Promise
      const affResult = userHandler(flatPayload);
      // affToPromise returns Effect (Promise Unit), call it to run the effect and get Promise
      return affToPromise(affResult)();
    };
  }
  
  // Handle eachMessage if present - wrap the handler
  if (opts.eachMessage) {
    const userHandler = opts.eachMessage;
    
    wrappedOpts.eachMessage = async (payload) => {
      // Call user handler (KafkaMessageFFI -> Aff Unit) and convert result to Promise
      const affResult = userHandler(payload);
      // affToPromise returns Effect (Promise Unit), call it to run the effect and get Promise
      return affToPromise(affResult)();
    };
  }
  
  return consumer.run(wrappedOpts);
};

export const disconnectConsumerImpl = (consumer) => consumer.disconnect();
