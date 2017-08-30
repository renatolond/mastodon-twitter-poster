(function() {
  return {
    graphitePort: 2003
    , graphiteHost: "carbon.hostedgraphite.com"
    , port: 8125
    ,backends: ["./backends/graphite"]
    ,    graphite: {
      legacyNamespace: false,
      globalPrefix: process.env.HOSTEDGRAPHITE_APIKEY
    }
  };
})()
