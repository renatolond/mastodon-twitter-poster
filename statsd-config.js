(function() {
  return {
    graphitePort: 2003
    , graphiteHost: "carbon.hostedgraphite.com"
    , port: 8125
    , debug: true
    , dumpMessages: true
    ,backends: ["./backends/graphite", "./backends/console"]
    ,    graphite: {
      legacyNamespace: false,
      globalPrefix: process.env.HOSTEDGRAPHITE_APIKEY
    }
  };
})()
