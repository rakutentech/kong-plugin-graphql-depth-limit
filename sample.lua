local parse = require 'kong-plugin.kong.plugins.graphql-depth-limit.parse'
local depthLimit = require 'kong-plugin.kong.plugins.graphql-depth-limit.depthLimit'

local query_with_fragment = parse [[
  {
    hero {
      ...NameAndAppearances
      friends {
        ...NameAndAppearances
        friends {
          ...NameAndAppearances
        }
      }
    }
  }

  mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
    createReview(episode: $ep, review: $review) {
      stars
      commentary
    }
  }
  
  fragment NameAndAppearances on Character {
    name
    appearsIn
  }

]]

local query_with_inline_fragments = parse [[
  query HeroForEpisode($ep: Episode!) {
    hero(episode: $ep) {
      name
      ... on Droid {
        primaryFunction
      }
      ... on Human {
        height
      }
    }
  }
]]

-- Parse a query
local ast = parse [[
query getUser($id: ID) {
  person(id: $id) {
    firstName
    lastName
    age
  }
}
]]


-- # depth = 2
local depthTestQueries = parse [[
query deep2 {
  viewer {
    albums {
      title
    }
  }
}

query deep3 {
  viewer {
    albums {
      ...musicInfo
      songs{
        ...musicInfo
      }
    }
  }
}

fragment musicInfo on Music {
  id
  title
  artists
}



query spaceXQueryD5 {
  launchesPast(limit: 10) {
    mission_name
    launch_date_local
    launch_site {
      site_name_long
    }
    links {
      article_link
      video_link
    }
    
    rocket {
      ...rocketInfo 
      
      second_stage {
        payloads {
          payload_type
          payload_mass_kg
          payload_mass_lbs
        }
      }
    }
    ships {
      name
      home_port
      image
    }
  }
}

fragment rocketInfo on LaunchRocket {
  rocket_name 
  first_stage {
        cores {
          flight
          core {
            reuse_count
            status
          }
        }
    }
}

query spaceXQueryD5 {
  launchesPast(limit: 10) {
    mission_name
    launch_date_local
    launch_site {
      site_name_long
    }
    links {
      article_link
      video_link
    }

    rocket {
      ...rocketInfo

      second_stage {
        payloads {
          payload_type
          payload_mass_kg
          payload_mass_lbs
        }
      }
    }
    ships {
      name
      home_port
      image
    }
  }
}

fragment rocketInfo on LaunchRocket {
  rocket_name
  first_stage {
        cores {
          flight
          core {
            reuse_count
            status
          }
        }
    }
}

]]



local error, result = pcall(depthLimit, depthTestQueries, 10)

if not error then
  print(result.message)
  print(result.operation)
end 