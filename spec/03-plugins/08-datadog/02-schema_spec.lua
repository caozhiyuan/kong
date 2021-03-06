local schemas = require "kong.dao.schemas_validation"
local datadog_schema = require "kong.plugins.datadog.schema"
local validate_entity = schemas.validate_entity

describe("Plugin: datadog (schema)", function()
  it("accepts empty config #o", function()
    local ok, err = validate_entity({}, datadog_schema)
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("accepts empty metrics", function()
    local metrics_input = {}
    local ok, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("accepts just one metrics", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {"K1:V1"}
      }
    }
    local ok, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("rejects if name or stat not defined", function()
    local metrics_input = {
      {
        name = "request_count",
        sample_rate = 1
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("name and stat_type must be defined for all stats", err.metrics)
    local metrics_input = {
      {
        stat_type = "counter",
        sample_rate = 1
      }
    }
    _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("name and stat_type must be defined for all stats", err.metrics)
  end)
  it("rejects counters without sample rate", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "counter",
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
  end)
  it("rejects invalid metrics name", function()
    local metrics_input = {
      {
        name = "invalid_name",
        stat_type = "counter",
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("unrecognized metric name: invalid_name", err.metrics)
  end)
  it("rejects invalid stat type", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "invalid_stat",
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("unrecognized stat_type: invalid_stat", err.metrics)
  end)
  it("rejects if customer identifier missing", function()
    local metrics_input = {
      {
        name = "status_count_per_user",
        stat_type = "counter",
        sample_rate = 1
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("consumer_identifier must be defined for metric status_count_per_user", err.metrics)
  end)
  it("rejects if metric has wrong stat type", function()
    local metrics_input = {
      {
        name = "unique_users",
        stat_type = "counter"
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("unique_users metric only works with stat_type 'set'", err.metrics)
    metrics_input = {
      {
        name = "status_count",
        stat_type = "set",
        sample_rate = 1
      }
    }
    _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("status_count metric only works with stat_type 'counter'", err.metrics)
  end)
  it("rejects if tags malformed", function()
    local metrics_input = {
      {
        name = "status_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {"T1:"}
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.not_nil(err)
    assert.equal("malformed tags: key 'T1:' has no value. Tags must be list of key[:value]", err.metrics)
  end)
  it("accept if tags is aempty list", function()
    local metrics_input = {
      {
        name = "status_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {}
      }
    }
    local _, err = validate_entity({ metrics = metrics_input}, datadog_schema)
    assert.is_nil(err)
  end)
end)
