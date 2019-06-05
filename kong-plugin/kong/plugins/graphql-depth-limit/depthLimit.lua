-- a port of https://github.com/stems/graphql-depth-limit 

local function getDefinitionsByKind(definitions, kind) 
    local map = {} 
    for _, definition in ipairs(definitions) do
        if definition.kind == kind then
            map[(definition.name and definition.name.value) or ''] = definition
        end
    end

    return map
end

local function getFragments(definitions) 
    return getDefinitionsByKind(definitions, 'fragmentDefinition')
end

local function getQueriesAndMutations(definitions) 
    return getDefinitionsByKind(definitions, 'operation')
end

local function determineDepth(node, fragments, depthSoFar, maxDepth, operationName, options)
    if depthSoFar > maxDepth then
        return error( {
            message = 'Operation ' .. operationName .. ' exceeds maximum operation depth of ' .. maxDepth,
            operation = operationName
        })
    end

    if node.kind == 'field' then

        -- TODO: ignore the introspection fields which begin with double underscores.
        -- TODO: use the options parameter to check for specified ignored fields.

        if node.selectionSet == nil then
            return 0
        end

        local maxDepthInSelections = 0
        for i, selection in ipairs(node.selectionSet.selections) do
            local selectionDepth = determineDepth(selection, fragments, depthSoFar + 1, maxDepth, operationName, options)
            if selectionDepth > maxDepthInSelections then maxDepthInSelections = selectionDepth end
        end

        return 1 + maxDepthInSelections; 

    elseif node.kind == 'fragmentSpread' then
        return determineDepth(fragments[node.name.value], fragments, depthSoFar, maxDepth, operationName, options)
   
    elseif 
        node.kind == 'inlineFragment' 
        or node.kind == 'operation' 
        or node.kind == 'fragmentDefinition' 
    then
        local maxDepthInSelections = 0
        for i, selection in ipairs(node.selectionSet.selections) do
            local selectionDepth = determineDepth(selection, fragments, depthSoFar, maxDepth, operationName, options)
            if selectionDepth > maxDepthInSelections then maxDepthInSelections = selectionDepth end
        end

        return maxDepthInSelections;
    else 
        error('Cannot handle this kind of node: ' .. node.kind) 
    end 
    
end

return function(tree, maxDepth) 
    local definitions = tree.definitions
    local fragments = getFragments(definitions)
    local queries = getQueriesAndMutations(definitions)

    local queryDepths = {}

    for name, query in pairs(queries) do 
        queryDepths[name] = determineDepth(query, fragments, 0, maxDepth, name, options)
    end

    return queryDepths
end