classdef Region
    properties
        Name
        Data % containers.Map: date -> [cases, deaths]
        StateMap % containers.Map: state name -> Region object
    end
    
    methods
        function obj = Region(name)
            obj.Name = name;
            obj.Data = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.StateMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
    end
end
