package main

import (
	"time"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	"go.uber.org/zap/zapcore"

	prom "github.com/prometheus/client_golang/prometheus"
	"github.com/uber-go/tally/v4"
	"github.com/uber-go/tally/v4/prometheus"
	sdktally "go.temporal.io/sdk/contrib/tally"

	wf "github.com/afitz0/customer-loyalty-workflow/go"
)

func main() {
	tryLocal := false

	logger := wf.NewZapAdapter(wf.NewZapLogger(zapcore.DebugLevel))
	metricsHandler := sdktally.NewMetricsHandler(newPrometheusScope(
		prometheus.Configuration{
			ListenAddress: "0.0.0.0:9099",
			TimerType:     "histogram",
		},
		logger,
	))

	c, err := client.Dial(client.Options{
		MetricsHandler: metricsHandler,
		HostPort:       "host.docker.internal:7244",
	})
	if err != nil {
		logger.Info("Unable to create Temporal client on Docker network. Attempting to fall back to localhost", "Error", err)
		tryLocal = true
	}

	if tryLocal {
		c, err = client.Dial(client.Options{
			MetricsHandler: metricsHandler,
			HostPort:       "127.0.0.1:7233",
		})
		if err != nil {
			logger.Error("Unable to create Temporal client", "Error", err)
			panic(err)
		}
	}
	defer c.Close()

	w := worker.New(c, wf.TaskQueue, worker.Options{})

	a := &wf.Activities{
		Client: c,
	}
	w.RegisterWorkflow(wf.CustomerLoyaltyWorkflow)
	w.RegisterActivity(a)

	err = w.Run(worker.InterruptCh())
	if err != nil {
		logger.Error("Unable to start worker.", "Error", err)
		panic(err)
	}
}

func newPrometheusScope(c prometheus.Configuration, logger *wf.ZapAdapter) tally.Scope {
	reporter, err := c.NewReporter(
		prometheus.ConfigurationOptions{
			Registry: prom.NewRegistry(),
			OnError: func(err error) {
				logger.Error("error in prometheus reporter", "Error", err)
			},
		},
	)
	if err != nil {
		logger.Error("error creating prometheus reporter")
		panic(err)
	}
	scopeOpts := tally.ScopeOptions{
		CachedReporter:  reporter,
		Separator:       prometheus.DefaultSeparator,
		SanitizeOptions: &sdktally.PrometheusSanitizeOptions,
		//Prefix:          "temporal_samples",
	}
	scope, _ := tally.NewRootScope(scopeOpts, time.Second)
	scope = sdktally.NewPrometheusNamingScope(scope)

	logger.Info("prometheus metrics scope created")
	return scope
}
