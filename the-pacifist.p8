pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

function _init()
    camx = 0
    camy = 0
    offset = 0
    shaking = false
    shake_timer=10
    score=0
    multiplier=1
    highscore=0
    lives=3
    gtms=0
    message='the pacifist'
    messageTimer=180
    bombs=1
    bombInUse=false
    bombTimer=60
    bombScale = 1
    bombRechargeT=0
    justDied=0
    powerUps={
        moreGates=0,
        bigGates=0,
        slowEasy=0,
        slowMedium=0,
        slowFast=0
    }
    difficulty=0 --0 to 1
    score2 = {0, 0, 0}
    highscore2 = {0, 0, 0}
    music(0)
    spawnRandomPU()
    spawnRandomPU()
    arenaSizeX = 192
    arenaSizeY = 192
    perfMode = false
    initcloth()
    menuitem(1, "Perf Mode: off", perfModeMenuCallback)
    easyBaseFrequency=120
    mediumBaseFrequency=240
    fastBaseFrequency=900
    easyFrequency=120
    mediumFrequency=240
    fastFrequency=900
end

function perfModeMenuCallback(b)
    if (b&1 > 0  or b&2 > 0) togglePerfMode()
    local menuText = "Perf Mode: off"
    if (perfMode) menuText = "Perf Mode: on"
    menuitem(_, menuText)
end

function togglePerfMode() perfMode = not perfMode end

function _update60()
    gtms+=1
    --difficulty = easeoutquart(flr(1000*(gtms/32400))/1000)
    --difficulty = easeinoutquad(flr(1000*(gtms/32400))/1000)
    if (difficulty < 1) difficulty = flr(1000*(gtms/28800))/1000
    if (not perfMode and gtms %2 == 0) updatecloth()
    updateAfterDeathTimer()
    updatePStuff()
    if (bombInUse) then
        manageActiveBomb()
    else 
        updateBombRechargeTime()
        if (btn(4)) then -- z button (bomb)
            useBomb()
        end
        if (p.dead == true and bombInUse == false) then
            playerDied()
        end

        updateShakeTimer()
        updateBombTimer()
        
        spawnStuff()

        foreach(fieldpus, managePU)
        foreach(gates, manageGate)
        heapsort(enemies, function(e1, e2) return getDistSquared(e1.x, e1.y, p.x, p.y)-getDistSquared(e2.x, e2.y, p.x, p.y) end)
        for k, v in pairs(enemies) do
        end
        foreach(enemies, manageEnemy)
        
        moveParticles()
    end
end

function _draw()
    screen_shake()
    cls()
    palt(0, true)
    if (bombInUse or perfMode) drawMatrix()
    if (p.x > 64-(p.cam_dx*4)) then if (p.x < arenaSizeX-64-(p.cam_dx*4)) then camx = p.x -64+(p.cam_dx*4) else camx = arenaSizeX-128 end else camx = 0 end
    if (p.y > 64-(p.cam_dy*4)-6) then if (p.y < arenaSizeY-64-(p.cam_dy*4)) then camy = p.y -64+(p.cam_dy*4) else camy = arenaSizeY-128 end else camy = -6 end
    camera(camx, camy)
    if (not bombInUse and not perfMode) drawcloth()
    foreach(fieldpus, drawFieldPU)
    foreach(gates, drawGateCircle)
    foreach(gates, drawGate)
    foreach(enemies, drawEnemy)
    foreach(particles, drawParticle)
    spr_r(lives-1, p.x-4, p.y-4, p.angle, 1, 1) --draw player
    drawBombBar()
    drawHUD()
    drawMessage()
end

function newRound() 
    enemies = {}
    gates = {}
    offset = 0
    shaking = false
    shake_timer=10
    multiplier=1
    p = Player:new{}
    lives -=1
end

function resetGame() 
    newRound()
    lives=3
    gtms = 0
    score=0
    score2 = {0, 0, 0}
    music(0)
    messageTimer=120
    message='try again'
    bombs=1
    bombInUse=false
    bombTimer=60
    bombScale = 1
    bombRechargeT=0
    powerUps={
        moreGates=0,
        bigGates=0,
        slowEasy=0,
        slowMedium=0,
        slowFast=0
    }
    difficulty=0 --0 to 1
    fieldpus = {}
    spawnRandomPU()
end

function spawnStuff()
    local gt = gtms/60
    local maxMediumFreq = 45
    local maxEasyFreq = 40
    local maxFastFreq = 120
    easyFrequency = flr(easyBaseFrequency*(1-difficulty*2.6))
    mediumFrequency = flr(mediumBaseFrequency*(1-difficulty*3.2))
    fastFrequency = flr(fastBaseFrequency*(1-difficulty))
    if (gtms % max(easyFrequency, maxEasyFreq) == 0) spawnEnemy(EasyE:new{})
    if (difficulty > 0.6 and gtms % max(easyFrequency+180, maxEasyFreq) == 0) spawnEnemy(EasyE:new{})
    if (gtms % max(mediumFrequency, maxMediumFreq) == 0) spawnEnemy(MediumE:new{})
    if (difficulty > 0.5 and gtms % max(mediumFrequency+240, maxMediumFreq) == 0) spawnEnemy(MediumE:new{})
    if (difficulty > 0.12 and gtms % max(fastFrequency, maxFastFreq) == 0) spawnEnemy(FastE:new{})
    -- if (gt > 15 and gt % 6 == 0) then
    --     local en = MediumE:new{}
    --     spawnEnemy(en)
    -- elseif (gt > 50 and gt % 2 == 0) then
    --     local en = MediumE:new{}
    --     spawnEnemy(en)
    -- elseif (gt > 100 and gt % 1 == 0) then
    --     local en = MediumE:new{}
    --     spawnEnemy(en)
    -- end
    -- if (gt > 120 and gt % 8 == 0) then
    --     local en = FastE:new{}
    --     spawnEnemy(en)
    -- elseif (gt > 30 and gt % 16 == 0) then
    --     local en = FastE:new{}
    --     spawnEnemy(en)
    -- end

    if gt % 45 == 0 then
        spawnRandomPU()
    end

    if (gt % (5-powerUps.moreGates) == 0) then
        newGate()
    end
end

function enemyCanSpawn(en)
    if (en.x < 2) then en.x = 2 end
    if (en.y < 2) then en.y = 2 end
    if (en.x > arenaSizeX-2) then en.x = arenaSizeX-2 end
    if (en.y > arenaSizeY-2) then en.y = arenaSizeY-2 end
    if getDist(en.x, en.y, p.x, p.y) < 42 then return false end

    local pa = p.angle-90%360
    local angle1 = (pa-30)/360
    local angle2 = (pa+30)/360
    local x1 = (sin(angle1)*100)+p.x
    local y1 = (cos(angle1)*100)+p.y
    local x2 = (sin(angle2)*100)+p.x
    local y2 = (cos(angle2)*100)+p.y
    if getTriPointCollision(x1, y1, x2, y2, p.x, p.y, en.x, en.y) == true then return false end
    return true
end

function spawnEnemy(en)
    repeat
        local angle = rnd()
        en.x = ((rnd(20)+42)*sin(angle))+p.x
        en.y = ((rnd(20)+42)*cos(angle))+p.y
    until enemyCanSpawn(en) == true
    add(enemies, en)
end

function newGate()
    local gate = MovingGate:new{}
    local bigGatesPU = powerUps.bigGates*2
    gate.angle = rnd(0.5)+0.5;
    local s = sin(gate.angle);
    gate.cx = rnd(arenaSizeX-20)+10;
    gate.cy = rnd(arenaSizeY-20)+10;
    gate.dx = rnd(gate.max_dx*2)-gate.max_dx
    gate.dy = rnd(gate.max_dy*2)-gate.max_dy
    gate.dangle = rnd(0.012)-0.006
    add(gates, gate)
    sfx(21)
end

function adjustScoreDistribution()
    if (score2[1] > 999) then 
        score2[2]+= flr(score2[1]/1000)
        score2[1] = score2[1]%1000
    end
    if (score2[2] > 999) then 
        score2[3]+= flr(score2[2]/1000)
        score2[2] = score2[2]%1000
    end
end

function adjustHighscore()
    if score2[3] > highscore2[3] then 
        updateHighscore()
    elseif score2[3] == highscore2[3] and score2[2] > highscore2[2] then
        updateHighscore()
    elseif score2[3] == highscore2[3] and score2[2] == highscore2[2] and score2[1] > highscore2[1] then
        updateHighscore()
    end

end

function updateHighscore()
    for i=1,3,1 do highscore2[i] = score2[i] end
end

function easeoutquart(t)
    t-=1
    return 1-t*t*t*t
end

function updatePStuff()
    p.dx*=p.friction
    p.dy*=p.friction
    local angle = p.angle%360

    if (btn(0)) then 
        p.dx-=p.acc
        p.cam_dx-=p.acc
        spawnTrail(p, 4)
        if angle > 180 then p.angle-=15 end
        if angle < 180 then p.angle+=15 end
        if (btn(2) and angle >= 180 and angle < 225) p.angle+=15
        if (btn(3) and angle <= 180 and angle > 135) p.angle-=15
        local disturbX = getPosInGridArrayFromRawPos(p.x)
        local disturbY = getPosInGridArrayFromRawPos(p.y)
        if (physparts[disturbX][disturbY].locked == false) then
            physparts[disturbX][disturbY].x-=1*(1-((p.x/16)+1-disturbX))*(1-((p.y/16)+1-disturbY))
        end
        if (physparts[disturbX][disturbY+1].locked == false) then
            physparts[disturbX][disturbY+1].x-=1*(1-((p.x/16)+1-disturbX))*(1-(disturbY+1-((p.y/16)+1)))
        end
    end -- left
    if (btn(1)) then 
        p.dx+=p.acc
        p.cam_dx+=p.acc
        spawnTrail(p, 4)
        if angle != 0 then
            if angle > 180 then p.angle+=15 end
            if angle <= 180 then p.angle-=15 end
        end
        if (btn(2) and (angle <=360 or angle == 0) and angle > 315) p.angle-=15
        if (btn(3) and angle >=0 and angle < 45) p.angle+=15
        local disturbX = getPosInGridArrayFromRawPos(p.x)
        local disturbY = getPosInGridArrayFromRawPos(p.y)
        if (physparts[disturbX][disturbY].locked == false) then
            physparts[disturbX][disturbY].x+=1*(1-((p.x/16)+1-disturbX))*(1-((p.y/16)+1-disturbY))
        end
        if (physparts[disturbX][disturbY+1].locked == false) then
            physparts[disturbX][disturbY+1].x+=1*(1-((p.x/16)+1-disturbX))*(1-(disturbY+1-((p.y/16)+1)))
        end
    end -- right
    if (btn(2)) then 
        p.dy-=p.acc
        p.cam_dy-=p.acc
        spawnTrail(p, 4)
        if ((angle <= 90 and angle >= 0) or angle > 270 ) then p.angle-=15 end
        if ((angle > 90 and angle <= 180) or (angle < 270 and angle >180)) then p.angle+=15 end
        if (btn(0) and angle <= 270 and angle > 225) p.angle-=15
        if (btn(1) and angle >= 270 and angle < 315) p.angle+=15
        local disturbX = getPosInGridArrayFromRawPos(p.x)
        local disturbY = getPosInGridArrayFromRawPos(p.y)
        if (physparts[disturbX][disturbY].locked == false) then
            physparts[disturbX][disturbY].y-=1*(1-((p.x/16)+1-disturbX))*(1-((p.y/16)+1-disturbY))
        end
        if (physparts[disturbX+1][disturbY].locked == false) then
            physparts[disturbX+1][disturbY].y-=1*(1-((p.y/16)+1-disturbY))*(1-(disturbX+1-((p.x/16)+1)))
        end
    end -- up
    if (btn(3)) then 
        p.dy+=p.acc
        p.cam_dy+=p.acc
        spawnTrail(p, 4)
        if ((angle < 90 and angle >= 0) or angle > 270 ) then p.angle+=15 end
        if (angle > 90 or (angle < 270 and angle >=180)) then p.angle-=15 end
        if (btn(0) and angle >= 90 and angle < 135) p.angle+=15
        if (btn(1) and angle <= 90 and angle > 45) p.angle-=15
        local disturbX = getPosInGridArrayFromRawPos(p.x)
        local disturbY = getPosInGridArrayFromRawPos(p.y)
        if (physparts[disturbX][disturbY].locked == false) then
            physparts[disturbX][disturbY].y+=1*(1-((p.x/16)+1-disturbX))*(1-((p.y/16)+1-disturbY))
        end
        if (physparts[disturbX+1][disturbY].locked == false) then
            physparts[disturbX+1][disturbY].y+=1*(1-((p.y/16)+1-disturbY))*(1-(disturbX+1-((p.x/16)+1)))
        end
    end -- down

    p.dx=mid(-p.max_dx,p.dx,p.max_dx)
    p.dy=mid(-p.max_dy,p.dy,p.max_dy)
    p.cam_dx=mid(-p.max_dx,p.cam_dx,p.max_dx)
    p.cam_dy=mid(-p.max_dy,p.cam_dy,p.max_dy)
    p.x+=p.dx
    p.y+=p.dy
    if (p.x>arenaSizeX-4) then p.x=arenaSizeX-4 end
    if (p.x<4) then p.x=4 end
    if (p.y>arenaSizeY-4) then p.y=arenaSizeY-4 end
    if (p.y<4) then p.y=4 end
end

function spawnTrail(o, r)
    local ang = rnd()
    local px = sin(ang)*r
    local py = cos(ang)*r
    local particle = Particle:new{
        max_frames=5,
        x = o.x+px,
        y = o.y+py,
        color = o.color
    }
    add(particles, particle)
end

function updateBombRechargeTime()
    if (bombRechargeT == 0 and bombs == 0) then bombs+=1 end
    if (bombRechargeT >0) then bombRechargeT-=1 end
end

function updateShakeTimer()
    if shake_timer == 0 then
        shaking = false
        shake_timer = 10
        offset=0
    end
    if shaking == true then 
        shake_timer-=1 
        offset=0.1
    end
end

function playerDied()
    addExplosionParticles(40,p.x, p.y, 7, 60, 1, p.dx, p.dy)
    sfx(2)
    shaking = true
    foreach(enemies, killEnemy)
    justDied = 20
    if lives>=2 then 
        newRound()
    else
        resetGame()
    end
end

function updateAfterDeathTimer()
    if justDied > 0 then justDied -= 1 end
end

function updateBombTimer()
    if bombTimer == 0 then 
        bombInUse = false
        bombTimer = 60
    end
end

function getPosInGridArrayFromRawPos(pos)
    return flr(pos/16)+1
end

function managePU(pu)
    pu.time-=1
    if pu.time == 0 then del(fieldpus, pu) end
    if (pu.x < p.x and 15+pu.x > p.x and pu.y < p.y and 15+pu.y > p.y) then
        pu:catch()
        sfx(20, 2)
        addPUParticles(20, pu.x, pu.y)
        del(fieldpus, pu)
    end
end

function manageGate(gate) 
    gate:move()
    if (getPointCircleCollision(gate.x1, gate.y1, p.x, p.y, 2) or getPointCircleCollision(gate.x2, gate.y2, p.x, p.y, 2) ) then 
        p.dx = p.dx*-1
        p.dy = p.dy*-1
    elseif (isTouchingPlayer(gate.x1, gate.y1, gate.x2, gate.y2, p.x, p.y)) then
        local enemiesKilled = 0
        local deadEnemies = {}
        foreach(enemies, function(e) printh(e.id, 'debug3.txt') end)
        foreach(enemies, function(enemy)
            printh(enemy.id, 'debug3.txt')
            if (getPointCircleCollision(enemy.x, enemy.y, gate.cx, gate.cy, 40+(powerUps.bigGates*3)) == true) then
                printh('KILLED', 'debug3.txt')
                score2[1]+=(enemy.points*multiplier)%1000
                score2[2]+=flr((enemy.points*multiplier)/1000)
                adjustScoreDistribution()
                score+=enemy.points*multiplier
                add(deadEnemies, enemy)
                enemiesKilled+=1
            end
        end)
        foreach(deadEnemies, function(e) killEnemy(e) end)
        adjustHighscore()
        shaking = true
        if enemiesKilled == 0 then sfx(0) else sfx(1) end
        addExplosionParticles(20, gate.cx, gate.cy, 10, 40, 5, 0, 0)
        del(gates, gate)
        multiplier+=enemiesKilled
        bombRechargeT-=120
        
        local disturbX = getPosInGridArrayFromRawPos(gate.cx)
        local disturbY =getPosInGridArrayFromRawPos(gate.cy)
        
        if (physparts[disturbX][disturbY].locked == false) then
            physparts[disturbX][disturbY].x+=30
            physparts[disturbX][disturbY].y+=30
        end
        if (physparts[disturbX+1][disturbY].locked == false) then
            physparts[disturbX+1][disturbY].x-=30
            physparts[disturbX+1][disturbY].y+=30
        end
        if (physparts[disturbX][disturbY+1].locked == false) then
            physparts[disturbX][disturbY+1].x+=30
            physparts[disturbX][disturbY+1].y-=30
        end
        if (physparts[disturbX+1][disturbY+1].locked == false) then
            physparts[disturbX+1][disturbY+1].x-=30
            physparts[disturbX+1][disturbY+1].y-=30
        end
    end
end

function manageEnemy(enemy)
    enemy:move()
    if (getPointCircleCollision(enemy.x, enemy.y, p.x, p.y, 2) == true and bombInUse == false) 
    then p.dead = true
    end --collide with player
end

function heapsort(t, cmp)
    local n = #t
    local i, j, temp
    local lower = flr(n / 2) + 1
    local upper = n
    if (#t < 2) return
    while 1 do
        if lower > 1 then
            lower -= 1
            temp = t[lower]
        else
            temp = t[upper]
            t[upper] = t[1]
            t[upper].id = upper
            upper -= 1
            if upper == 1 then
                t[1] = temp
                t[1].id = 1
                return
            end
        end
        i = lower
        j = lower * 2
        while j <= upper do
            if j < upper and cmp(t[j], t[j+1]) < 0 then
                j += 1
            end
            if cmp(temp, t[j]) < 0 then
                t[i] = t[j]
                t[i].id = i
                i = j
                j += i
            else
                j = upper + 1
            end
        end
        t[i] = temp
        t[i].id = i
    end
end

function killEnemy(e)
    e:die() 
    del(enemies, e)
end

function useBomb()
    if (bombs > 0 and justDied == 0 and bombInUse == false) then
        bombInUse = true
        message='dimensional shift'
        messageTimer=60
        sfx(4, 2)
        bombs-=1
        bombRechargeT=5400
    else
        sfx(12, 2)
    end
end

function manageActiveBomb()
    bombScale = (((cos((bombTimer/120))*32)+32)/8)+1
    bombTimer -= 1
    for e in all(enemies) do
        local ratiox = (e.x/128)/(e.y/128)
        local ratioy = (e.y/128)/(e.x/128)
        e.x*=bombScale
        e.y*=bombScale
        if (e.x > 130 or e.y > 130) then del(enemies, e) end
    end
    for p in all(particles) do
        local ratiox = (p.x/128)/(p.y/128)
        local ratioy = (p.y/128)/(p.x/128)
        p.x*=bombScale
        p.y*=bombScale
        if (p.x > 130 or p.y > 130) then del(particles, p) end
    end
    for g in all(gates) do
        local ratiox = (g.cx/128)/(g.cy/128)
        local ratioy = (g.cy/128)/(g.cx/128)
        g.cx*=bombScale
        g.cy*=bombScale
        g.x1*=bombScale
        g.y1*=bombScale
        g.x2*=bombScale
        g.y2*=bombScale
        if (g.cx > arenaSizeX+20 or g.cy > arenaSizeY+20) then del(gates, g) end
    end
    if (bombTimer == 0) then 
        bombScale=1
        
        local px = p.x
        local py = p.y
        local pa = p.angle
        p = Player:new{
            x = px,
            y = py,
            angle = pa
        }
        bombInUse = false 
    end
end

function spawnRandomPU()
    local pus =
    {
        [1] = spawnMoreGatesPU,
        [2] = spawnBigGatesPU,
        [3] = spawnSlowEasyPU,
        [4] = spawnSlowMediumPU,
    }
    local rand = rnd(4)
    local i = flr(rand)+1
    if i == 5 then i = 4 end
    pus[i]()
end

function spawnMoreGatesPU()
    local pu = MoreGatesPU:new{}
    pu:spawn()
    add(fieldpus, pu)
end
function spawnBigGatesPU()
    local pu = BigGatesPU:new{}
    pu:spawn()
    add(fieldpus, pu)
end
function spawnSlowEasyPU()
    local pu = SlowEasyPU:new{}
    pu:spawn()
    add(fieldpus, pu)
end
function spawnSlowMediumPU()
    local pu = SlowMediumPU:new{}
    pu:spawn()
    add(fieldpus, pu)
end
function spawnSlowFastPU()
    local pu = SlowFastPU:new{}
    pu:spawn()
    add(fieldpus, pu)
end

function drawGateCircle(gate)
    circ(gate.cx, gate.cy, 40+(powerUps.bigGates*3), 1)
end

function drawGate(gate)
    circfill(gate.x1,gate.y1,1,10)
    circfill(gate.x2,gate.y2,1,10)
    line(gate.x1, gate.y1, gate.x2, gate.y2, 11)
end

function drawEnemy(e)
    if (getIsInRect(e.x, e.y, camx-4, camy-4, camx+132, camy+132)) e:draw()
end

function drawParticle(part)
    if getIsInRect(part.x, part.y, camx-16, camy-16, camx+144, camy+144) then
        rectfill(part.x, part.y, part.x, part.y, part.color)
    end
end

function drawFieldPU(pu)
    
    if (getIsInRect(pu.x, pu.y, camx-16, camy-16, camx+144, camy+144)) pu:draw()
end

function drawMatrix()
    -- rectfill(-20, -20, 148, 148, 0)
    local newMod = 0
    if (bombInUse == true) then
        --if (bombTimer < 40) then
        newMod = ((cos((bombTimer/120))*32)+32)/64
        --end
        for x=0-camx,128-camx,16 do
            line(x*newMod, 0*newMod, x*newMod, 160*newMod, 1)
        end
        for y=0-camy,128-camy,16 do
            line(0*newMod, y*newMod, 160*newMod, y*newMod, 1)
        end
    end
    for x=-64-camx,arenaSizeX+64-camx,16 do
        line(x*bombScale, -64, x*bombScale, 320, 1)
    end
    for y=-64-camy,arenaSizeY+64-camy,16 do
        line(-64, y*bombScale, 320, y*bombScale, 1)
    end
    line(0, 0, 0, 127, 1)
    line(127, 127, 127, 0, 1)
    line(127, 127, 0, 127, 1)
end

function drawHUD()
    local sc = getScoreString2(score2)
    local mlt = ''..multiplier..'x'
    rectfill(0+camx, 0+camy, 128+camx, 6+camy, 0)
    line(0+camx, 6+camy, 128+camx, 6+camy, 1)
    print(getScoreString2(highscore2),
    0+camx,0+camy, 6)
    print(getScoreString2(score2),
    (64-#sc*2)+camx,0+camy, 6)
    print(mlt,
        128-#mlt*4+camx,0+camy, 6)
end

-- function getScoreString(sc)
--     local ret = '0';
--     if (sc[1] > 0 or sc[2] > 0 or sc[3] > 0) then
--         local prefix = ''
--         if (sc[2] > 0 or sc[3] > 0) and sc[1] < 10 then prefix = '00' elseif (sc[2] > 0 or sc[3] > 0) and sc[1] < 100 then prefix = '0' end
--         ret = prefix..sc[1]
--         if (sc[2] > 0 and sc[3] > 0) then
--             if sc[2] < 10 then prefix = '00' elseif sc[2] < 100 then prefix = '0' else prefix = '' end
--             ret = prefix..sc[2]..ret
--         elseif (sc[2] > 0 and sc[3] == 0) then ret = sc[2]..ret end
--     end
--     if (sc[3] > 0) then ret = sc[3]..ret end
--     return ret
-- end

function getScoreString2(sc)
    local ret=''..sc[1]
    if (sc[2] > 0 or sc[3] > 0) then
        while (#ret < 3) do ret = '0'..ret end
        ret=sc[2]..ret
        if (sc[3] > 0) then
            while (#ret < 6) do ret = '0'..ret end
            ret = sc[3]..ret
        end
    end
    return ret
end

function drawBombBar()
    local bombMeterW = ((5400-bombRechargeT)/5400)*127
    line(0+camx, 127+camy, bombMeterW+camx , 127+camy, 12)
end

function drawMessage()
    if (messageTimer > 0) then
        print(message, (64-#message*2)+camx, 61+camy, 11)
        messageTimer -=1
    end
end

Shape = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    max_dx=2,
    max_dy=2,
    acc = 0,
    friction=0.90,
    id=1
}
MovingGate = {
    x1=0,
    x2=0,
    y1=10,
    y2=0,
    cx=0,
    cy=0,
    angle=0,
    exploding=false,
    max_dx=0.3,
    max_dy=0.3,
    dangle=0,
    animationT=10,
    radius=0
}
Particle = {
    x=0,
    y=0,
    dx = 0,
    dy = 0,
    max_frames=30,
    friction=0.70,
    color=10,
    frames = 0
}
PowerUp = {
    x=0,
    y=0,
    time=600
}

function PowerUp:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function Particle:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function MovingGate:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function Shape:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

PUParticle = Particle:new{
    max_frames=70,
    friction=1,
    color=6,
    dx=0.5,
    dy=0.5,
    frames = 0
}

MoreGatesPU = PowerUp:new{
    sprite=20
}
BigGatesPU = PowerUp:new{
    sprite=21
}
SlowEasyPU = PowerUp:new{
    sprite=22
}
SlowMediumPU = PowerUp:new{
    sprite=23
}
SlowFastPU = PowerUp:new{
    sprite=24
}
Player = Shape:new{
    sprite = 0,
    x=96,
    y=96,
    max_dx=3,
    max_dy=3,
    acc = 0.15,
    angle = 0,
    dead = false,
    color = 6,
    cam_dx=0,
    cam_dy=0
}
EasyE = Shape:new{
    x=60,
    y=60,
    max_dx=0.7,
    max_dy=0.7,
    acc = 0.03,
    friction=0.975,
    color=9,
    points=2
}
MediumE = Shape:new{
    x=60,
    y=60,
    max_dx=0.1,
    max_dy=0.1,
    acc = 0.05,
    friction=0.965,
    color=8,
    points=3
}
FastE = Shape:new{
    x=60,
    y=60,
    max_dx=1.90,
    max_dy=1.90,
    acc = 0.17,
    friction=0.94,
    color=14,
    colors={14, 7},
    timer=180,
    activeTime=110,
    angle=0,
    points=10,
    signaling=false,
    cr=0,
    crd=0.5
}

function Particle:move()
    self.frames+=1
    self.x+=(self.dx*self.friction)
    self.y+=(self.dy*self.friction)
    if (self.frames >= self.max_frames) then del(particles, self) end
end

function PUParticle:move()
    self.frames+=1
    local diffx =  self.x - p.x
    local diffy = self.y - p.y
    local angle = atan2(diffx, diffy*-1)
    self.dx += 0.15*(cos(angle)*-1)
    self.dy += 0.15*sin(angle)
    self.dx*=self.friction
    self.dy*=self.friction
    self.x+=self.dx
    self.y+=self.dy
    if (self.frames >= self.max_frames) then del(particles, self) end
    if getPointCircleCollision(self.x, self.y, p.x, p.y, 6) then del(particles, self) end
end

function PowerUp:spawn()
    self.x = flr(rnd(12))*16
    self.y = flr(rnd(12))*16
end

function PowerUp:draw()
    rectfill(self.x, self.y, 16+self.x, 16+self.y, 1)
    spr(self.sprite, 4+self.x, 4+self.y)
end

function MoreGatesPU:catch()
    if powerUps.moreGates < 4 then
        powerUps.moreGates+=1
    end
    
end

function BigGatesPU:catch()
    powerUps.bigGates+=1
end

function SlowEasyPU:catch()
    powerUps.slowEasy+=0.04
end

function SlowMediumPU:catch()
    powerUps.slowMedium+=0.04
end

function SlowFastPU:catch()
    powerUps.slowFast+=0.05
end

function Shape:draw() 
    circfill(self.x,self.y,2,self.color)
end
function FastE:draw() 
    if (self.signaling == true) then
        circ(self.x, self.y, self.cr, 7)
    end
    circfill(self.x,self.y,2,self.color)
end

function MovingGate:move()
    self.cx+=self.dx
    self.cy+=self.dy
    self.angle+=self.dangle
    if (self.angle>=1) then self.angle-=1 end
    local gateSin = sin(self.angle)
    local gateCos = cos(self.angle)
    if (self.animationT > 0) then
        self.animationT -= 1
        self.radius += 1
    end
    self.x1 = self.cx+((self.radius+(powerUps.bigGates*3))*gateSin);
    self.x2 = self.cx+((-self.radius-(powerUps.bigGates*3))*gateSin);
    self.y1 = self.cy+((self.radius+(powerUps.bigGates*3))*gateCos);
    self.y2 = self.cy+((-self.radius-(powerUps.bigGates*3))*gateCos);
    
    if (self.cx>arenaSizeX-10 or self.cx<10) then self.dx*=-1 end
    if (self.cy>arenaSizeY-10 or self.cy<10) then self.dy*=-1 end
end

function Shape:move()
    local diffx =  self.x - p.x
    local diffy = self.y - p.y
    local angle = atan2(diffx, diffy*-1)
    local dx = self.dx + self.acc*cos(angle)*-1
    local dy = self.dy + self.acc*sin(angle)
    dx = dx * self.friction
    dy = dy * self.friction
    self:setSpeedDiff()
    local shouldGoForward = true
    local dist = -1
    local i = self.id
    local didHit = false
    repeat
        i-=1
        local dxSum = 0
        local dySum = 0
        if (enemies[i] != nil) then
            dist = getDistSquared(enemies[i].x, enemies[i].y, self.x+dx, self.y+dy)

            if (dist < 16) then
                local divider = 2
                repeat 
                    dx = (self.dx + self.acc*cos(angle)*-1)/divider
                    dy = (self.dy + self.acc*sin(angle))/divider
                    dist = getDistSquared(enemies[i].x, enemies[i].y, self.x+dx, self.y+dy)
                    divider *= 2
                until divider == 8 or dist >= 16
                
                if (dist < 16) didHit = true
            end
        end
    until dist >= 4 or didHit == true or enemies[i] == nil or i == 1

    -- for en in all(enemies) do
    --     if (self != en) then
    --         if (getDist(self.x+self.dx, self.y+self.dy, en.x, en.y) < 2) then
    --             if (getDist(en.x, en.y, p.x, p.y) < getDist(self.x, self.y, p.x, p.y)) then
    --                 shouldGoForward = false
    --             end
    --         end
    --     end
    -- end
    if (didHit == false) then
        self.dx = dx
        self.dy = dy
        self.x+=self.dx
        self.y+=self.dy
    end
    if (self.x>arenaSizeX-2) then self.x=arenaSizeX-2 end
    if (self.x<2) then self.x=2 end
    if (self.y>arenaSizeY-2) then self.y=arenaSizeY-2 end
    if (self.y<2) then self.y=2 end
end

function Shape:die() addExplosionParticles(20, self.x, self.y, self.color, 20, 3, self.dx, self.dy) end

function FastE:manageRipple()

    if (self.cr <=7 and self.signaling == true) then
        self.cr+=self.crd
    elseif (self.cr >7 and self.signaling == true) then
        self.cr = 0
        self.signaling = false
    end
        
end

function FastE:move()
    self.timer+=-1
    if self.signaling == true then
        self:manageRipple()
    end
    if ((self.timer >= 60 and self.timer%30 == 0) or (self.timer < 60 and self.timer >= 0 and self.timer%15 == 0)) then
        if (self.colors[1] == self.color) then 
            self.color = self.colors[2] 
            self.signaling = true
            sfx(3, 1)
            local disturbX = getPosInGridArrayFromRawPos(self.x)
            local disturbY = getPosInGridArrayFromRawPos(self.y)
            for i=0,3 do
                local distModY = i%2
                if (distModY != 0) distModY = 1
                local distModX = (i/2)%2
                if (distModX != 0) distModX = 1
                if (physparts[disturbX+distModX][disturbY+distModY].locked == false) then
                    physparts[disturbX+distModX][disturbY+distModY].x = self.x
                    physparts[disturbX+distModX][disturbY+distModY].y = self.y
                end
            end
        else self.color = self.colors[1] end
    end
    if (self.timer <= 0 and self.timer >= self.activeTime*-1) then
        local diffx =  self.x - p.x
        local diffy = self.y - p.y
        local angle = atan2(diffx, diffy*-1)
        self.dx += self.acc*cos(angle)*-1
        self.dy += self.acc*sin(angle)
        self.dx*=self.friction
        self.dy*=self.friction
        self:setSpeedDiff()
        self.x+=self.dx
        self.y+=self.dy
        
        if (self.x>arenaSizeX-2) then self.x=arenaSizeX-2 end
        if (self.x<2) then self.x=2 end
        if (self.y>arenaSizeY-2) then self.y=arenaSizeY-2 end
        if (self.y<2) then self.y=2 end
    elseif (self.timer < self.activeTime*-1) then
        self.timer = 180
    end
end

function EasyE:setSpeedDiff()
    self.dx*=(1-powerUps.slowEasy/1.5)
    self.dy*=(1-powerUps.slowEasy/1.5)
end
function MediumE:setSpeedDiff()
    self.dx*=(1-powerUps.slowMedium/1.5)
    self.dy*=(1-powerUps.slowMedium/1.5)
end
function FastE:setSpeedDiff()
    self.dx*=(1-powerUps.slowFast)
    self.dy*=(1-powerUps.slowFast)
end

-- helper
function screen_shake()
    local fade = 0.95
    local offset_x=16-rnd(32)
    local offset_y=16-rnd(32)
    offset_x*=offset
    offset_y*=offset
    
    camera(offset_x,offset_y)
    offset*=fade
    if offset<0.05 then
      offset=0
    end
end

function getIsInRect(px, py, x1, y1, x2, y2)
    return (px > x1 and py > y1 and px < x2 and py < y2)
end

function getDist(x1, y1, x2, y2)
    local distx = x1/10 - x2/10
    local disty = y1/10 - y2/10
    return (sqrt((distx*distx) + (disty*disty)))*10
end

function getDistSquared(x1, y1, x2, y2)
    local dx = x2 - x1;
    local dy = y2 - y1;
    return dx * dx + dy * dy;
end   

function getPointCircleCollision(px, py, cx, cy, r)
    local dist = getDist(px, py, cx, cy)
    if (dist <= r) then return true end
    return false
end

function getLinePointCollision(x1, y1, x2, y2, px, py)
    local d1 = getDist(px, py, x1, y1)
    local d2 = getDist(px, py, x2, y2)
    local lineLen = getDist(x1, y1, x2, y2)
    local buffer = 0.1

    if (d1+d2 >= lineLen-buffer and d1+d2 <= lineLen+buffer) then return true end
    return false
end

function getTriPointCollision(x1, y1, x2, y2, x3, y3, px, py)
    local areaOrig = abs( (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1))
    local area1 =    abs( (x1-px)*(y2-py)-(x2-px)*(y1-py))
    local area2 =    abs( (x2-px)*(y3-py)-(x3-px)*(y2-py))
    local area3 =    abs( (x3-px)*(y1-py)-(x1-px)*(y3-py))
    if (flr(area1 + area2 + area3) == flr(areaOrig)) then
        return true;
    end
    return false;
end

function isTouchingPlayer(gateX1, gateY1, gateX2, gateY2, playerX, playerY)
    -- if (getPointCircleCollision(gateX1, gateY1, playerX, playerY, 3) or getPointCircleCollision(gateX2, gateY2, playerX, playerY, 3) ) then return true end
    local len = getDist(gateX1, gateY1, gateX2, gateY2)
    local dot = (((playerX-gateX1)*(gateX2-gateX1)) + ((playerY-gateY1)*(gateY2-gateY1))) / (len^2)
    local closestX = gateX1 + (dot * (gateX2-gateX1))
    local closestY = gateY1 + (dot * (gateY2-gateY1))
    local onSegment = getLinePointCollision(gateX1, gateY1, gateX2, gateY2, closestX, closestY)
    if (onSegment != true) then return false end

    local distance = getDist(closestX, closestY, playerX, playerY)

    if (distance <= 2) then return true end
    return false
end

function easeinoutquad(t)
    if(t<.5) then
        return t*t*2
    else
        t-=1
        return 1-t*t*2
    end
end

function tan(a) return sin(a)/cos(a) end

function addExplosionParticles(n, x, y, c, duration, speed, dxMod, dyMod)
    for i=1,n,1 do
        local dx = rnd(speed*2)-(speed)+dxMod
        local dy = rnd(speed*2)-(speed)+dyMod
        local particle = Particle:new{x=x, y=y, dx = dx, dy = dy, color = c, max_frames= duration}
        add(particles, particle)
    end
end

function addPUParticles(n, x, y)
    for i=1,n,1 do
        local particle = PUParticle:new{x=rnd(16)+x, y=rnd(16)+y, max_frames=70}
        add(particles, particle)
    end
end
--  end helper

-- Credit: https://www.lexaloffle.com/bbs/?pid=94828


function moveParticles() 
    foreach(particles, moveParticle)
end

function moveParticle(part)
    part:move()
end

function spr_r(s,x,y,a,w,h)
    sw=(w or 1)*8
    sh=(h or 1)*8
    sx=(s%8)*8
    sy=flr(s/8)*8
    x0=flr(0.5*sw)
    y0=flr(0.5*sh)
    a=a/360
    sa=sin(a)
    ca=cos(a)
    for ix=sw*-1,sw+4 do
        for iy=sh*-1,sh+4 do
            dx=ix-x0
            dy=iy-y0
            xx=flr(dx*ca-dy*sa+x0)
            yy=flr(dx*sa+dy*ca+y0)
            if (xx>=0 and xx<sw and yy>=0 and yy<=sh-1 and sget(sx+xx,sy+yy) != 0) then
                pset(x+ix,y+iy,sget(sx+xx,sy+yy))
            end
        end
    end
end

p = Player:new{}
enemies = {}
gates = {}
particles = {}
fieldpus = {}

-- physics by aatish https://www.lexaloffle.com/bbs/?pid=84525

physics = {
    physparts = {},
    springs = {},

    ax = 0,
    ay = 0,
    dt = 0.1,

    setforce = function(this, _ax, _ay)
        this.ax = _ax
        this.ay = _ay
    end,

    reset = function(this)
        this.physparts = {}
        this.springs = {}
    end,

    addphyspart = function(this, pa)
        add(this.physparts, pa)
    end,

    addspring = function(this, s)
        add(this.springs, s)
    end,

    update = function(this)
        for pa in all(this.physparts) do
            pa:update(this.ax, this.ay, this.dt)
        end

        for s in all(this.springs) do
            s:update()
        end

    end
}

function spring(_p1, _p2, _length, _stiffness)
    return {
        p1 = _p1,
        p2 = _p2,
        length = _length,
        stiffness = _stiffness,

        update = function(this)

            local dx = this.p2.x - this.p1.x
            local dy = this.p2.y - this.p1.y
            local d2 = sqrt(dx*dx + dy*dy)
            local d3 = (d2 - this.length)/d2
           
            if (not(this.p1.locked)) then
                this.p1.x += 0.5*dx*d3*this.stiffness
                this.p1.y += 0.5*dy*d3*this.stiffness
            end

            if (not(this.p2.locked)) then
                this.p2.x -= 0.5*dx*d3*this.stiffness
                this.p2.y -= 0.5*dy*d3*this.stiffness
            end

        end
    }
end

function physpart(_x,_y)
    return {
        x = _x,
        y = _y,
        x1 = _x,
        y1 = _y,
        locked = false,

        lock = function(this)
            this.locked = true
        end,

        unlock = function(this)
            this.locked = false
        end,

        update = function(this, ax, ay, dt)

            if (not(this.locked)) then

                this.tempx = this.x
                this.tempy = this.y

                this.x += this.x - this.x1 + ax*dt*dt
                this.y += this.y - this.y1 + ay*dt*dt

                this.x1 = this.tempx
                this.y1 = this.tempy

                this.x = min(max(0, this.x), arenaSizeX)
                this.y = min(max(0, this.y), arenaSizeY)

            end
        end

    }
end

function initcloth()
    physics:reset()
    physparts = {}
    springs = {}

    
    for x=1,13 do
        local physparts_x = {}
        for y=1,13 do
            local pa = physpart((x*16)-16, (y*16)-16)
            if (x == 1) then 
                pa:lock()
            end
            if (x == 13) then 
                pa:lock()
            end
            if (y == 1) then 
                pa:lock()
            end
            if (y == 13) then 
                pa:lock()
            end
            add(physparts_x, pa)
            physics:addphyspart(pa)
        end
        add(physparts, physparts_x)
    end

    for x=1,13 do
        for y=1,13 do
            if (x<13) then
                local s = spring(physparts[x][y],
                                    physparts[x+1][y],
                                    15, 1)
                physics:addspring(s)
            end
            if (y<13) then
                local s = spring(physparts[x][y],
                physparts[x][y+1],
                                    15, 1)
                physics:addspring(s)
            end
        end
    end

    physics:setforce(0,10)
end

function updatecloth()
    physics:update()
    -- physics:setforce(sin(time()/5), 10 + cos(time()/3))
    physics:setforce(sin(time()/3), cos(time()/3))
end

function drawcloth()
    for x=1,13 do
        for y=1,13 do
            if (x<13) then
                line(physparts[x][y].x,
                                    physparts[x][y].y,
                                    physparts[x+1][y].x,
                                    physparts[x+1][y].y,
                                    1)
            end
            if (y<13) then
                line(physparts[x][y].x,
                                    physparts[x][y].y,
                                    physparts[x][y+1].x,
                                    physparts[x][y+1].y,
                                    1)
            end
        end
    end
    line(arenaSizeX-1, arenaSizeY-1, arenaSizeX-1, 0, 1)
    line(arenaSizeX-1, arenaSizeY-1, 0, arenaSizeY-1, 1)
end



__gfx__
5d000000d6000000760000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d500006d6d000067670000d5d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d00d6d6d600767676005d5d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5d56d6d6d6d67676767d5d5d5d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dd6d6d6d6767676765d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5006d6d6d0067676700d5d5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d0000d6d60000767600005d5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d50000006d00000067000000d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004400000044000050d0000000d0000000d000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000043000050433005050d0005050d0005050d00050500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000003005550333000000d0005000d0005000d0005000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000003005000333000d0000000d0000000d000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000003000000333000d0999000d0888000d0eee0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000300000033300009990000088800000eee0000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000034000003340009990000088800000eee0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000
11000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000010
11000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000010
11000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000010
11100000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000110
11000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000010
11100000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000110
11100000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000110
11110000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000110
11110000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000001110
11110000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000001110
11110000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000001110
11111000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000011110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111100000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000111110
11111110000000000000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000000000000001111110
11111110000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000001111110
1111111100000000000000000000000000000005d500000000000000000001111111000000000000000000000000000000000000000000000000000011111110
01111111000000000000000000ddd6dd6dd6dd0d6d00000000000000000001111111100000000000000000000000000000000000000000000000000011111110
01111111000000000000000000d6666666666d0d6600000000000000000001111111000000000000000000000000000000000000000000000000000011111110
011111110000000000000000005dddd66dddd50d6d00000000000000000001111111100000000000000000000000000000000000000000000000000011111110
011111110000000000000000000000066500000d6d56dd6d00005d6dd6dd01111111000000000000000000000000000000000000000000000000000011111110
011111111000000000000000000000066500000d66d66666600566666666d1111111100000000000000000000000000000000000000000000000000011111110
001111111000000000000000000000066500000d6d155556650d6d55555661111111000000000000000000000000000000000000000000000000000111111100
001111111000000000000000000000066500000d6600000d650d6500005661111111100000000000000000000000000000000000000000000000001111111100
000111111100000000000000000000066500000d6d000006650665d66666d1111111000000000000000000000000000000000000000000000000000111111000
001111111100000000000000000000066500000d6d00000d650d6566666d011ddd511001d6666666615dd5000000000000000000000000000000001111111100
000111111100000555555555510000066500000d6600000d650d6d0000000116665100566666666661566d000000000000000000000555000000001111111000
00011111110005666666666666d000066500000d6d0000066505666666000116665110666666666661566d000000000000000000001666000000001111111000
000111111100566666666666666d00066500000d6d00000d6500d666660000111111056665111111100111000000000000000000001666000000001111110000
0000111111106666dddddddd666650000000000000000000000000000000011111111566d0000000000000000000000000000000001666000000011111110000
0000111111116660000000000d6660000011111110000000000111111111001555110566d0111111111111000001111111110001115666111111011111110000
0000111111156660000000000066610001666666666100000d6666666666111666511566d066666666666d0005666666666d0056666666666665011111110000
000011994111666300000033006d61000166666666661000dd6d6666666d3016665105d6d0d66d6666666d0056666db6666d00566d66666d66d5119941100000
00000499991566630303333333dbd30003db3bdb36d66335bdb6d6bdbd6b3336bd3333bdb3dbdbdbdbdbdd33d66bdbd6dbdb3056b6bd66b6bdb3349999110000
00000999bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb999100000
000004999415dbd30330003003dbd33005dbddb3336db333d633333303333036665135663333333303366d30bdbdbdbdbdb33333333dbd333033399994000000
0000009945156d6055555535d666d00166d66666d066600b665000330000011d66530566d000303000566d03566d66666bd60030003666330301114991000000
0000001111156660d66666666666100d66666666d066600d665000000000001666511566d000000000566d00056666666666d000001666000001111111000000
0000001111156660d666666666610016665111111066600d665000000000011666510566d000000000566d000001111115666000001666000001111111000000
00000011111566605ddddddd550000166d0000000066600d665000000000001666510566d000000000566d000000000000666100001666000001111110000000
00000001111566600000000000000016660000000166600d66d111111111011666511566d000000000566d001111111115666100001666000001111110000000
00000000111566600000000000000006666666666666d005666666666666101666510566d000000000566d00d666666666666000001666000011111110000000
000000001115666000000000000000056666666666661000d66666666666111666511566d000000000566d00d666666666661000001666000011111100000000
000000001115666000000000000000001d66666666d0000005d666666666101666510566d000000000566d00d666666666d10000001666000111111100000000
00000000111111100000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000000111111100000000
00000000111111100000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000111111100000000
00000000011111100000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000000111111000000000
00000000011111100000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000
00000000001111110000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000001111110000000000
00000000001111110000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000001111110000000000
00000000011111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111111000000000
00000000001111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000011111110000000000
00000000000111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111100000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
00000000000011111100000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111111000000000000
00000000000001111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000001111110000000000000
00000000000001111100000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111110000000000000
00000000000001111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000001111110000000000000
00000000000001111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000001111110000000000000
00000000000000111111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000011111100000000000000
00000000000000111111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000011111100000000000000
00000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000011111000000000000000
00000000000000011111100000000000000000000000000000000000000000111111000000000000000000000000000000000000000011111000000000000000
00000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000111111000000000000000
00000000000000011111100000000000000000000000000000000000000000111111000000000000000000000000000000000000000011111000000000000000
00000000000000011111100000000000000000000000000000000000000005499451000000000000000000000000000000000000000111111000000000000000
00000000000000001111110000000000000000000000000000000000000049999994000000000000000000000000000000000000001111110000000000000000
00000000000000001111110000000000000000000000000000000000000599999999500000000000000000000000000000000000001111110000000000000000
00000000000000000111110000000000000000000000000000000000000499999999400000000000000000000000000000000000001111100000000000000000
00000000000000000111110000000000000000000000000000000000000999999999900000000000000000000000000000000000001111100000000000000000
00000000000000000111110000000000000000000000000000000000000999999999900000000000000000000000000000000000001111100000000000000000
00000000000000000111111000000000000000000000000000000000000499999999400000000000000000000000000000000000011111100000000000000000
00000000000000000111111000000000000000000000000000000000000599999999500000000000000000000000000000000000011111000000000000000000
00000000000000000011111100000000000000000000000000000000000049999994000000000000000000000000000000000000111111000000000000000000
00000000000000000001111100000000000000000000000000000000000005499451000000000000000000000000000000000000111110000000000000000000
0000000000000000001111110000000000000000000000000000014eed2000011111022888000000000000000000000000000000111111000000000000000000
00000000000000000001111100000000000000000000000000002eeeeee200011111288888820000000000000000000000000000111110000000000000000000
0000000000000000000111110000000000000000000000000001eeeeeeee20011112888888880000000000000000000000000000111110000000000000000000
0000000000000000000111110000000000000000000000000004eeeeeeeed0011118888888888000000000000000000000000000111110000000000000000000
000000000000000000001111100000000000000000000000000eeeeeeeeee0011118888888888000000000000000000000000001111100000000000000000000
000000000000000000001111110000000000000000000000000eeeeeeeeee0011118888888888000000000000000000000000011111100000000000000000000
111111111111111111111111111111111111111111111111111eeeeeeeeee1111118888888888111111111111111111111111111111111111111111111111110
1111111111111111111111111111111111111111111111111115eeeeeeee51111112888888882111111111111111111111111111111111111111111111111110
0111111111111111111111111111111111111111111111111111deeeeeed11111111288888821111111111111111111111111111111111111111111111111110
0000000000000000000001111100000000000000000000000000024eed2000011111022888000000000000000000000000000011111000000000000000000000
00000000000000000000001111000000000000000000000000000000000000011111000000000000000000000000000000000011110000000000000000000000
00000000000000000000001111100000000000000000000000000000000000011111000000000000000000000000000000000111110000000000000000000000
00000000000000000000001111100000000000000000000000000000000000011110000000000000000000000000000000000111110000000000000000000000
00000000000000000000001111110000000000000000000000000000000000011111000000000000000000000000000000001111110000000000000000000000
00000000000000000000001111100000000000000000000000000000000000011111000000000000000000000000000000000111110000000000000000000000
00000000000000000000000111110000000000000000000000000000000000011111000000000000000000000000000000001111100000000000000000000000
00000000000000000000000111100000000000000000000000000000000000011110000000000000000000000000000000001111000000000000000000000000
00000000000000000000000011110000000000000000000000000000000000011111000000000000000000000000000000001111000000000000000000000000
00000000000000000000000011111000000000000000000000000000000000011111000000000000000000000000000000011111000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
4a040500396513f6613f6712b6710e60109601006010c601086010660108601036010260100601245012450124501235012350100501005013250132501325013250132501325013250132501325013250132501
52040000376503e6503e650356501c65014650134500e4500b4500643004410034000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
ce060b00396533f6633d673396733865334653296531e653136530965302653006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
000c01002b3302a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
340400003f7333e7233e7233d7233c7233b7233772333723337232c7232972326723237231e7231972315733107330d7330a74308743077430574303743037430374302743017430074300743007430270300703
1c1800000c0700c0700c0700c0700c0700c0700e070110700c0700c0700c0700c0700c0700c0700e070110701407014070140701407014070140700e0700f0701107011070110701107011070110700f0700e070
0018000000563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c64300503
931800003f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f615
d10c00201f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f100
921800003f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f605
d10c00001d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f105
2d1800001832018320183201832018320183201a3201d3201832018320183201832018320183201a3201d3202032020320203202032020320203201a3201b3201d3201d3201d3201d3201d3201d3201b3201a320
a410000008565005052e5050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
931810003f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f6053f6153f605
0118100000563005030c6430050324600005630c6430050300563005030c6430c64324600005630c6430c64300563005030c6430050324600005630c6430050300563005630c6430c64324600005630c6430c643
4f1800000c0300c0300c0300c0300c0300c0300e030110300c0300c0300c0300c0300c0300c0300e030110301403014030140301403014030140300f030110300c0300c0300c0300c0300c0300c0300f0300e030
d01800201f1251e1001f1051f1001f1251f1001f1051f1001f1251e1001f1051f1001f1251f1001f1051f1001f1251e1001f1051f1001f1251f1001f1051f1001f1251e1001d1051d1001f1251f1001d1051f100
d11800201f1251e1001f1251f1001f1251f1001f1251f1001f1251e1001f1251f1001f1251f1001f1251f100201251e100201251f100201251f100201251f100181251e10018125171001812518100181251f100
2c1800001832018320133201832018320133201a3201d3201832018320143201832018320143201a3201d3202032020320143202032020320143201a3201b3201d3201d320143201d3201d3201d3201b3201a320
011800001853518535135351853518535135351a5351d5351853518535145351853518535145351a5351d5352053520535145352053520535145351a5351b5351d5351d535145351d5351d5351d5351b5351a535
1606000029353135531a553225532a5532f5533755300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
1003090003751087510c751107511275112751107510b751067510270119701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
__music__
00 45465008
00 45460908
00 05460908
01 05060708
00 05060708
00 05060708
00 05060708
00 0506070b
00 0506070b
00 450e0d48
00 0f060950
00 0f0e0d13
00 0f0e0713
00 0f0e0713
00 05060712
02 05060712

