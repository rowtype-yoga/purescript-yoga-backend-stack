export const createAdminImpl = (kafka) => kafka.admin();

export const connectAdminImpl = (admin) => admin.connect();

export const createTopicsImpl = (admin, opts) => admin.createTopics(opts);

export const deleteTopicsImpl = (admin, opts) => admin.deleteTopics(opts);

export const listTopicsImpl = (admin) => admin.listTopics();

export const disconnectAdminImpl = (admin) => admin.disconnect();
