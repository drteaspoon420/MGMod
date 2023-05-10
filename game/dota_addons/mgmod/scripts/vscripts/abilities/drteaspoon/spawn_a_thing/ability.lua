drteaspoon_spawn_a_thing = class({})
function drteaspoon_spawn_a_thing:OnSpellStart()
	local hCaster = self:GetCaster()
	local vPoint = self:GetCursorPosition()
	local vOrigin = hCaster:GetAbsOrigin()

    self:SpawnAThing(vPoint,"prefabs/forest")
end

function drteaspoon_spawn_a_thing:SpawnAThing(vPos,sMap)
    vPos = self:Gridify(vPos)
    local hMap = DOTA_SpawnMapAtPosition(
        sMap,
        vPos, 
        false,
        Dynamic_Wrap( drteaspoon_spawn_a_thing, "OnRoomReadyToSpawn" ),
        Dynamic_Wrap( drteaspoon_spawn_a_thing, "OnSpawnRoomComplete" ),
        nil )
end

function drteaspoon_spawn_a_thing:Gridify(vPos)
    vPos = Vector( 
        math.floor(vPos.x/64)*64,
        math.floor(vPos.y/64)*64,
        (math.floor(vPos.z/64)-2)*64
    )
    return vPos
end


function drteaspoon_spawn_a_thing:OnRoomReadyToSpawn(hSpawnGroupHandle)
    print("ready to spawn")
end
function drteaspoon_spawn_a_thing:OnSpawnRoomComplete(hSpawnGroupHandle)
    print("spawn complete")
end