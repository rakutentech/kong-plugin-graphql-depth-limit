local parse = require 'kong.plugins.graphql-depth-limit.parse'
local depthLimit = require 'kong.plugins.graphql-depth-limit.depthLimit'

local plugin = require("kong.plugins.base_plugin"):extend()

-- Priority is set to execute this plugin after the rate limiting plugin
plugin.PRIORITY = 910

plugin.VERSION = "0.0.1"

-- TODO: this should be a plugin parameter
local maxDepth = 3

function plugin:new()
    plugin.super.new(self, "graphql-depth-limit")
end

function plugin:access(conf)
    plugin.super.access(self)
  
    local requestMethod = kong.request.get_method()

    -- don't check if preflight request
    if requestMethod == "OPTIONS" then
      return
    end

    -- TODO: Implement GET request by parsing the "query" query string
    -- See https://graphql.org/learn/serving-over-http/#get-request
    if requestMethod == "GET" then
        return
    end

    -- TODO: Add support for Content-type: application/graphql
    local body, err = kong.request.get_body('application/json')
    if err then
        kong.log.err(err)
        return kong.response.exit(415, { message = "Unsupported Media Type" })
    end

    kong.log.inspect(body)

    kong.log(body.query)

    local parse_success, tree = pcall(parse, body.query)

    if not parse_success then 
        return kong.response.exit(400, { message = "Body format is incorrect" })
    end

    local depth_check_pass, report = pcall(depthLimit, tree, maxDepth)

    kong.log.inspect(report)

    -- TODO: return an error message formatted in GraphQL-friendly format
    if not depth_check_pass then
        return kong.response.exit(400, 
            [[
{
    "errors": [
        {
            "message": "query exceeds complexity limit",
            "extensions": {
                "code": "GRAPHQL_VALIDATION_FAILED"
            }
        }
    ]
}
            ]], 
        {
                ["Content-Type"] = "application/json"
        })
    end 
  end
  
  return plugin