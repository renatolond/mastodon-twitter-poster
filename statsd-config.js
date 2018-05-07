(function() {
  return {
    librato: {
      email: process.env.LIBRATO_EMAIL,
      token: process.env.LIBRATO_TOKEN
    }
    , backends: ["statsd-librato-backend"]
    , port: 8125
    , keyNameSanitize: false
    , deleteIdleStats: true
  };
})()
