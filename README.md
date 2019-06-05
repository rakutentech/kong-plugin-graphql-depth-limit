# GraphQL Depth Limit plugin for [Kong](https://konghq.com/)
Limit the complexity of GraphQL queries based on their depth.

## Plugin Description
Verify requests body for a valid GraphQL document and determine the total depth of each operation (query or mutation).

The plugin will either proxy the request to your upstream services if every operations in the request are below the specified threshold, or discard the request if not.

## Feature Support

- Specify depth limit parameter (Work in progress)

## Configuration

#### Enabling the plugin on a Service
Configure this plugin on a Service by making the following request:
```
$ curl -X POST http://kong:8001/services/{service}/plugins \
    --data "name=graphql-depth-limit"
```
`service`: the id or name of the Service that this plugin configuration will target.

#### Enabling the plugin on a Route
Configure this plugin on a Route with:
```
$ curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=graphql-depth-limit"
```
`route_id`: the id of the Route that this plugin configuration will target.


#### Global plugins
All plugins can be configured using the http://kong:8001/plugins/ endpoint. A plugin which is not associated to any Service, Route or Consumer (or API, if you are using an older version of Kong) is considered "global", and will be run on every request.

#### Parameters
Here's a list of all the parameters which can be used in this plugin's configuration:

| Parameter |  | Default | Description |
| :---: | :---: | :---: | :---: |
| `name` |  |  | The name of the plugin to use, in this case `paseto`. |
| `service_id` |  |  | The id of the Service which this plugin will target. |
| `route_id` |  |  | The id of the Route which this plugin will target. |
| `enabled` |  | `true` | Whether this plugin will be applied. |


## Development environment

### Preparing the development environment

Once you have Vagrant installed, follow these steps to set up a development
environment for both Kong itself as well as for custom plugins. It will
install the development dependencies like the `busted` test framework.

```shell
# clone this repository
$ git clone https://github.com/rakutentech/kong-plugin-graphql-depth-limit
$ cd kong-plugin-graphql-depth-limit

# clone the Kong repo (inside the plugin one)
$ git clone https://github.com/Kong/kong

# build a box with a folder synced to your local Kong and plugin sources
$ vagrant up

# ssh into the Vagrant machine, and setup the dev environment
$ vagrant ssh
$ cd /kong
$ make dev

# To run this custom plugin, tell Kong to load it
$ export KONG_PLUGINS=bundled,graphql-depth-limit

# startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
# we will also need to ensure that migrations are up to date
$ cd /kong
$ bin/kong migrations bootstrap
$ bin/kong start
```

This will tell Vagrant to mount your local Kong repository under the guest's
`/kong` folder, and the 'kong-plugin' repository under the
guest's `/kong-plugin` folder.

To verify Kong has loaded the plugin successfully, execute the following
command from the host machine:

```shell
$ curl http://localhost:8001
```
In the response you get, the plugins list should now contain an entry
"graphql-depth-limit" to indicate the plugin was loaded.

To start using the plugin, execute from the host:
```shell
# create an api that simply forward queries to Star Wars API, using a
# 'catch-all' setup with the `uris` field set to '/'
$ curl -i -X POST \
  --url http://localhost:8001/services/ \
  --data 'name=swapi' \
  --data 'url=https://swapi.apis.guru/'

$ curl -i -X POST \
  --url http://localhost:8001/services/swapi/routes \
  --data 'paths=/'

# add the graphql depth limit plugin to our new api
$ curl -i -X POST \
  --url http://localhost:8001/services/swapi/plugins \
  --data 'name=graphql-depth-limit'
```


## License

MIT License - see the [LICENSE](LICENSE) file for details

- This project uses the parser from https://github.com/bjornbytes/graphql-lua.

- The Depth limit evaluation implementation is a port of https://github.com/stems/graphql-depth-limit 

- The Development environment Vagrant file and documentation uses https://github.com/Kong/kong-vagrant
