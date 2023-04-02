
DebugLevel = 100 -- 0|ERROR  5|WARNING  10|System  100|lenght of lists  200|vectors
-- I marked lines where I need to add more code. with "#EDITHERE"

--------------
-- Settings --
--------------

-- I have already created 5 different missile groups. You can give luanchers one of the names
-- from "LaunchpadName" and it will be controlled by the Ai
-- named like the "ControllingAiName" says and it will behave like "MissileBehaviourName" says.
-- You can remove or add groups.
-- You can change the settings of a group, which are:
-- 1. LaunchpadName, 2. ControllingAiName, 3. MissileBehaviourName

--                      LaunchpadName     ControllingAiName    MissileBehaviourName
GuidanceGroups =  { { "missiles 01", "missile ai 01", "Diving01"},
                    {"missiles 02",   "missile ai 02",     "Diving01"},
                    {"missiles 03",   "missile ai 03",     "Diving01"},
                    {"missiles 04",   "missile ai 04",     "Diving01"},
                    {"missiles 05",   "missile ai 05",     "Diving01"}
                    }

-- Here you can define different behaviours for missiles.
-- You can then tell a missile group, what behaviour to use.
-- To do so, just match "FlightBehaviourName" and "MissileBehaviourName" and
-- the GuiadanceGroup will know what MissileBehaviour to use

-- There are multiple BehaviourPattern to choose from. They each require different settings.
-- Here is a list of behaviours I implemented:

-- 1.
-- BehaviourPatternName: "Diving"
-- This BehaviourPattern has 3 options:
-- 1. FlightBehaviourName: A GuiadanceGroup with this MissileBehaviourName will use this BehaviourPattern.
-- 2. CruisingAltitude: The cruising altitude the missile will stay at, bevore diving on the enemy
-- 3. DivingRadius: The distance to the enemy (no respect to altitude difference) below which we dive.

--2.
-- BehaviourPatternName: "CustomCurve"
-- not done yet



--                BehaviourPattern    FlightBehaviourName   CruisingAltitude   DivingRadius     (#unfinished)
MissileBehaviours = {{"Diving",       "Diving01",           200,               500         }} -- flies on CruisingAltitude till being within DivingRadius, when it strickes down on enemy








-- This function is called each game tick by the game engine
-- The object named "I" contains a bunch of data related to the game
function Update(I)
    GeneralGuiadance(I)
end



-- This is the main function organising my functions
function GeneralGuiadance(I)
    if GeneralGuidanceInitDone ~= true then
        GeneralGuidanceInit(I)
    else
        GeneralGuidanceUpdate(I)
    end

end



-- This is what controls the launchpads
function GeneralGuidanceUpdate(I)
    -- iterates GuidanceGroups
    for GuidanceGroupId, GuidanceGroupData in pairs(GuidanceGroups) do
        if GuidanceGroupData.Valid then
            local MissileBehaviour = MissileBehaviours[GuidanceGroupData.MissileBehaviourId]
            local TargetInfo = I:GetTargetInfo(GuidanceGroupData.MainframeId, 0)
            local AimPointPosition = TargetInfo.AimPointPosition
            local BehaviourPattern = MissileBehaviour[1]

            -- iterates launchpads
            for key, luaTransceiverIndex in pairs(GuidanceGroupData.luaTransceiverIndexes) do
                -- iterates missiles
                for missileIndex=0 , I:GetLuaControlledMissileCount(luaTransceiverIndex)-1 do
                    local matched = false
                    if MissileData[luaTransceiverIndex] == nil then MissileData[luaTransceiverIndex] = {} end
                    if MissileData[luaTransceiverIndex][missileIndex] == nil then MissileData[luaTransceiverIndex][missileIndex] = {} end

                    -- here the correct MissileControl function is selected
                    if BehaviourPattern == "Diving" then MissileControlDiving(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition);           matched = true end
                    if BehaviourPattern == "CustomCurve" then MissileControlCustomCurve(I,luaTransceiverIndex,missileIndex,MissileBehaviour,AimPointPosition); matched = true end
                    -- more behaviours to come #EDITHERE

                    if not matched then MyLog(I,5,"WARNING:  GuidanceGroup with LaunchpadName ".. GuidanceGroupData[1].. " has no working MissileBehaviour!") end
                end
            end
        end
    end
end



-- creates lists of all the launchpads Ids so addressing them is optimised
-- finds Ids of controlling ai mainframes
-- finds Id of MissileBehaviour
function GeneralGuidanceInit(I)
    I:ClearLogs()
    MyLog(I,10,"Running GeneralGuidanceInit")
    GeneralGuidanceInitDone = false
    local ErrorDetected = false

    -- a list containing a set of data for each missile
    MissileData = {}

    -- iterates GuidanceGroups
    local LuaTransceiverCount = I:GetLuaTransceiverCount()
    for GuidanceGroupId, GuidanceGroupData in pairs(GuidanceGroups) do
        local LaunchpadName = GuidanceGroupData[1]
        local ControllingAiName = GuidanceGroupData[2]
        local MissileBehaviourName = GuidanceGroupData[3]

        local GuidanceGroupIsSetUpCorrect = true

        -- finds all the launchpads Ids
        local LaunchpadIds = {}
        for luaTransceiverIndex=0 , LuaTransceiverCount-1 do
            local LuaTransceiverInfo = I:GetLuaTransceiverInfo(luaTransceiverIndex)
            if LuaTransceiverInfo.CustomName == LaunchpadName then
                table.insert(LaunchpadIds,luaTransceiverIndex)
            end
        end
        GuidanceGroups[GuidanceGroupId].luaTransceiverIndexes = LaunchpadIds
        if #LaunchpadIds == 0 then MyLog(I,5,"WARNING:  GuidanceGroup with LaunchpadName "..LaunchpadName.. " has no assigned launchpads!"); GuidanceGroupIsSetUpCorrect = false end

        -- iterating ai mainframes
        for index=0 ,I:Component_GetCount(26)-1 do -------------------------------------------------------------------------------------------------- not sure about indexing
            if I:Component_GetBlockInfo(26,index).CustomName == ControllingAiName then
                GuidanceGroups[GuidanceGroupId].MainframeId = index
            end
        end
        if GuidanceGroups[GuidanceGroupId].MainframeId == nil then MyLog(I,5,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no assigned ai mainframe!"); GuidanceGroupIsSetUpCorrect = false end

        -- iterating MissileBehaviours
        for MissileBehaviourId, MissileBehaviour in pairs(MissileBehaviours) do
            -- checks if the MissileGuiadance group can find a MissileBehaviour
            if MissileBehaviourName == MissileBehaviour[2] then
                GuidanceGroups[GuidanceGroupId].MissileBehaviourId = MissileBehaviourId
            end
        end
        if GuidanceGroups[GuidanceGroupId].MissileBehaviourId == nil then MyLog(I,5,"WARNING:  GuiadanceGroup with LaunchpadName "..LaunchpadName.. " has no configurated MissileBehaviour!"); GuidanceGroupIsSetUpCorrect = false end
        

        GuidanceGroups[GuidanceGroupId].Valid = GuidanceGroupIsSetUpCorrect
    end

    if ErrorDetected == false then
        GeneralGuidanceInitDone = true
    else
        MyLog(I,10,"GeneralGuidanceInit failed")
    end
end



-- guides missiles along waypoints
-- lti = luaTransceiverIndex | mi = missileIndex
function MissileControlDiving(I,lti,mi,MissileBehaviour,AimPointPosition)


    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local CruisingAltitude = MissileBehaviour[3]
    local DivingRadius = MissileBehaviour[4]

    local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
    local Position = MissileInfo.Position

    -- resets MissileData for a new missile
    if TimeSinceLaunch < 0.1 then
        MissileData[lti][mi] = {}
    else
        if Position.y > CruisingAltitude then
            MissileData[lti][mi].Waypoint01 = true -- vertical launch done
        end

        if (AimPointPosition - Vector3(Position.x,AimPointPosition.y,Position.z)).magnitude < DivingRadius then
            MissileData[lti][mi].Waypoint02 = true -- cruising done
        end

        if MissileData[lti][mi].Waypoint01 ~= true then
            aimPoint = Position + Vector3(0,10,0)

        elseif MissileData[lti][mi].Waypoint02 ~= true then
            aimPoint = Vector3  (AimPointPosition.x,CruisingAltitude,AimPointPosition.z)
        else
            aimPoint = AimPointPosition
        end
        I:SetLuaControlledMissileAimPoint(lti,mi,aimPoint.x,aimPoint.y,aimPoint.z)
    end
end


-- #EDITHERE
function MissileControlCustomCurve(I,lti,mi,MissileBehaviour,AimPointPosition)
    local MissileInfo = I:GetLuaControlledMissileInfo(lti,mi)
    local TimeSinceLaunch = MissileInfo.TimeSinceLaunch
    local Position = MissileInfo.Position

    local m_apt_Vector = AimPointPosition - Position
    local m_apt_Distance = m_apt_Vector.magnitude
    local m_apt_PlaneVector = Vector3(AimPointPosition.x,0,AimPointPosition.z) - Vector3(Position.x,0,Position.z)
    local m_apt_PlaneDistance = m_apt_PlaneVector.magnitude
    local m_apt_Elevation = math.acos(m_apt_PlaneDistance / m_apt_Distance)


    -- resets MissileData for a new missile
    if TimeSinceLaunch < 0.1 then
        MissileData[lti][mi] = {}
        MissileData[lti][mi].LaunchPosition = Position
        MissileData[lti][mi].m_apt_InitialPlaneDistance = m_apt_PlaneDistance
    else
        local x = MissileData[lti][mi].m_apt_InitialPlaneDistance /2
        local height = AimPointPosition.y + 0
    end
end


















function MyLog(I,priority,message)
    if priority <= DebugLevel then
        I:Log(message)
    end
end