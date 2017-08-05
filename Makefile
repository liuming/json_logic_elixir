.PHONY: test

all:
	mix do deps.get, compile

test:
	MIX_ENV=test mix do credo, test
