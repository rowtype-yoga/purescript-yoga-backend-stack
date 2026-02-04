export const serveImpl = (options) => Bun.serve(options);

// String/text Response
export const stringResponseImpl = (body, stuff) => new Response(body, stuff);

// JSON Response
export const jsonResponseImpl = (body, stuff) => Response.json(body, stuff);

// Empty Response (for 204 No Content, etc.)
export const emptyResponseImpl = (stuff) => new Response(null, stuff);

// Response with ArrayBuffer
export const arrayBufferResponseImpl = (buffer, stuff) => new Response(buffer, stuff);

// Static Response constructors
export const responseRedirectImpl = (url, status) => Response.redirect(url, status);

export const responseErrorImpl = () => Response.error();

// Response cloning
export const cloneResponseImpl = (response) => response.clone();
