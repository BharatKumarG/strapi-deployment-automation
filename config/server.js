// config/server.js
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    // Strapi’s session middleware requires at least two keys:
    keys: env.array('APP_KEYS'),
  },
});
