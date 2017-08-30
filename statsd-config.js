(function() {
  return {
    librato: {
      email: process.env.LIBRATO_EMAIL,
      token: process.env.LIBRATO_TOKEN,
      tags: { dyno: process.env.DYNO }
    }
    , backends: ["statsd-librato-backend"]
    , port: 8125
    , keyNameSanitize: false
    , deleteIdleStats: true
  };
})()
