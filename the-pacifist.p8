pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

offset = 0
shaking = false
shake_timer=0
score=0
multiplier=1
highscore=0
lives=3
gtms=0
message='the pacifist'
messageTimer=180

function _init()
    save('@clip')
    offset = 0
    shaking = false
    shake_timer=0
    score=0
    multiplier=1
    music(0)
end

function newRound() 
    enemies = {}
    gates = {}
    offset = 0
    shaking = false
    shake_timer=0
    multiplier=1
    player = Player:new{}
    lives -=1
end

function resetGame() 
    newRound()
    lives=3
    gtms = 0
    score=0
    music(0)
    messageTimer=120
    message='try again'
end

function drawMessage()
    if (messageTimer > 0) then
        print(message, 64-#message*2, 61, 11)
        messageTimer -=1
    end
end

function enemyCanSpawn(en)
    if (en.x < 2) then en.x = 2 end
    if (en.y < 2) then en.y = 2 end
    if (en.x > 126) then en.x = 126 end
    if (en.y > 126) then en.y = 126 end
    if getDist(en.x, en.y, player.x, player.y) < 42 then return false end

    local pa = player.angle-90%360
    print(''..pa, 20, 20, 1)
    local angle1 = (pa-30)/360
    local angle2 = (pa+30)/360
    local x1 = (sin(angle1)*100)+player.x
    local y1 = (cos(angle1)*100)+player.y
    local x2 = (sin(angle2)*100)+player.x
    local y2 = (cos(angle2)*100)+player.y
    if getTriPointCollision(x1, y1, x2, y2, player.x, player.y, en.x, en.y) == true then return false end
    return true
end

function spawnEnemy(en)
    repeat
        local angle = rnd()
        en.x = ((rnd(20)+42)*sin(angle))+player.x
        en.y = ((rnd(20)+42)*cos(angle))+player.y
    until enemyCanSpawn(en) == true
    add(enemies, en)
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

function _update60() --called at 60fps
    if (player.dead == true and shake_timer == 10) then
        if lives>=2 then 
            newRound()
        else
            resetGame()
        end
        
    end
    gtms+=1
    local gt = gtms/60
    if shake_timer == 10 then
        shaking = false
        shake_timer = 0
        offset=0
    end
    if shaking == true then 
        shake_timer+=1 
        offset=0.1
    end
    if (gt % 3 == 0) then
        local en = EasyE:new{}
        spawnEnemy(en)
    elseif (gt >=40 and gt % 1.5 == 0) then
        local en = EasyE:new{}
        spawnEnemy(en)
    elseif (gt >=60 and gt*10 % 8 == 0) then
        local en = EasyE:new{}
        spawnEnemy(en)
    elseif (gt >=80 and gt*10 % 5 == 0) then
        local en = EasyE:new{}
        spawnEnemy(en)
    end
    if (gt > 15 and gt % 6 == 0) then
        local en = MediumE:new{}
        spawnEnemy(en)
    elseif (gt > 50 and gt % 2 == 0) then
        local en = MediumE:new{}
        spawnEnemy(en)
    elseif (gt > 100 and gt % 1 == 0) then
        local en = MediumE:new{}
        spawnEnemy(en)
    end
    if (gt > 30 and gt % 10 == 0) then
        local en = FastE:new{}
        spawnEnemy(en)
    end

    if (gt % 5 == 0) then
        local gate = MovingGate:new{}
        gate.angle = rnd(0.5)+0.5;
        gate.halfCircleSin = sin(gate.angle);
        gate.centerPosX = rnd(116);
        gate.centerPosY = rnd(116);
        gate.x1 = gate.centerPosX+(10*gate.halfCircleSin);
        gate.x2 = gate.centerPosX+(-10*gate.halfCircleSin);
        gate.y1 = gate.centerPosY+(10*(1-gate.halfCircleSin));
        gate.y2 = gate.centerPosY+(-10*(1-gate.halfCircleSin));
        gate.dx = rnd(gate.max_dx)
        gate.dy = rnd(gate.max_dy)
        gate.dangle = rnd(0.012)-0.006
        add(gates, gate)
    end


    player.dx*=player.friction
    player.dy*=player.friction
    local angle = player.angle%360
    if (btn(0)) then 
        player.dx-=player.acc
        spawnTrail(player, 4)
        if angle > 180 then player.angle-=10 end
        if angle < 180 then player.angle+=10 end
    end -- left
    if (btn(1)) then 
        player.dx+=player.acc
        spawnTrail(player, 4)
        if angle != 0 then
            if angle > 180 then player.angle+=10 end
            if angle <= 180 then player.angle-=10 end
        end
    end -- right
    if (btn(2)) then 
        player.dy-=player.acc
        spawnTrail(player, 4)
        if ((angle <= 90 and angle >= 0) or angle > 270 ) then player.angle-=10 end
        if ((angle > 90 and angle <= 180) or (angle < 270 and angle >180)) then player.angle+=10 end
    end -- up
    if (btn(3)) then 
        player.dy+=player.acc
        spawnTrail(player, 4)
        if ((angle < 90 and angle >= 0) or angle > 270 ) then player.angle+=10 end
        if (angle > 90 or (angle < 270 and angle >=180)) then player.angle-=10 end
    end -- down
    -- if angle == 0 then player.angle = 0 end
    player.dx=mid(-player.max_dx,player.dx,player.max_dx)
    player.dy=mid(-player.max_dy,player.dy,player.max_dy)

    player.x+=player.dx
    player.y+=player.dy
    if (player.x>124) then player.x=124 end
    if (player.x<4) then player.x=4 end
    if (player.y>124) then player.y=124 end
    if (player.y<4) then player.y=4 end
    
    for gate in all(gates) do
        gate.centerPosX+=gate.dx
        gate.centerPosY+=gate.dy
        gate.angle+=gate.dangle
        if (gate.angle>=1) then gate.angle-=1 end
        local gateSin = sin(gate.angle)
        local gateCos = cos(gate.angle)
        gate.x1 = gate.centerPosX+(10*gateSin);
        gate.x2 = gate.centerPosX+(-10*gateSin);
        gate.y1 = gate.centerPosY+(10*(gateCos));
        gate.y2 = gate.centerPosY+(-10*(gateCos));
        
        if (gate.centerPosX>120 or gate.centerPosX<0) then gate.dx*=-1 end
        if (gate.centerPosY>120 or gate.centerPosY<0) then gate.dy*=-1 end
        
        if (getPointCircleCollision(gate.x1, gate.y1, player.x, player.y, 2) or getPointCircleCollision(gate.x2, gate.y2, player.x, player.y, 2) ) then 
            player.dx = player.dx*-1
            player.dy = player.dy*-1
        elseif (isTouchingPlayer(gate.x1, gate.y1, gate.x2, gate.y2, player.x, player.y)) then
            local soundPlayed = false
            local enemiesKilled = 0
            for enemy in all(enemies) do
                if (getPointCircleCollision(enemy.x, enemy.y, gate.centerPosX, gate.centerPosY, 40) == true) then
                    if soundPlayed == false then
                        sfx(1)
                        soundPlayed = true
                    end
                    enemy:die()
                    score+=enemy.points*multiplier
                    if score > highscore then highscore = score end
                    del(enemies, enemy)
                    enemiesKilled+=1
                end
            end
            shaking = true
            sfx(0)
            for i=1,20,1 do
                local dx = rnd(10)-5
                local dy = rnd(10)-5
                local particle = Particle:new{x=gate.centerPosX, y=gate.centerPosY, dx = dx, dy = dy}
                add(particles, particle)
            end
            del(gates, gate)
            multiplier+=enemiesKilled
        end
    end
    for enemy in all(enemies) do
		enemy:move()
        if (getPointCircleCollision(enemy.x, enemy.y, player.x, player.y, 2) == true) then
            shaking = true
            sfx(2)
            for i=1,40,1 do
                local dx = rnd(4)-2
                local dy = rnd(4)-2
                local particle = Particle:new{x=player.x, y=player.y, dx = dx, dy = dy, color = 7, max_frames= 60}
                add(particles, particle)
                player.dead = true
            end
            for enemy2 in all(enemies) do 
                enemy2:die() 
                del(enemies, enemy2)
            end
        end

    end
    moveParticles()
end

function _draw()
    screen_shake()
    cls() -- clear screen
    palt(0, true)
    drawMatrix()
    print(''..score,
      0,0, 6)
    print('H.SCORE: '..highscore,
    40,0, 6)
    print(''..multiplier..'x',
        110,0, 6)
    for gate in all(gates) do
        circfill(gate.x1,gate.y1,1,10)
        circfill(gate.x2,gate.y2,1,10)
        circ(gate.centerPosX, gate.centerPosY, 40, 1)
        line(gate.x1, gate.y1, gate.x2, gate.y2, 11)
    end
    -- drawTriangle()
    spr_r(lives-1, player.x-4, player.y-4, player.angle, 1, 1) -- draw the sprite using the values of our player object 
    for enemy in all(enemies) do
		circfill(enemy.x,enemy.y,2,enemy.color)
        local edistx = player.x - enemy.x
        local edisty = player.y - enemy.y
        local edist = sqrt((edistx*edistx) + (edisty*edisty))
        local diffx =  enemy.x - player.x
        local diffy = enemy.y - player.y 
        local angle = atan2(diffx, diffy*-1)
        local dx = sin(angle)
        local dy = cos(angle)
        -- print(''..dx,
        -- 0,0, 6)
        -- print(''..dy,
        -- 60,0, 6)
    end
    for particle in all(particles) do
        rectfill(particle.x, particle.y, particle.x, particle.y, particle.color)
        particle.frames+=1
    end
        
    drawMessage()
end

function drawTriangle()
    local pa = player.angle-90%360
    print(''..pa, 20, 20, 1)
    local angle1 = (pa-30)/360
    local angle2 = (pa+30)/360
    local x1 = (sin(angle1)*100)+player.x
    local y1 = (cos(angle1)*100)+player.y
    local x2 = (sin(angle2)*100)+player.x
    local y2 = (cos(angle2)*100)+player.y
    local color = 1
    for en in all(enemies) do
        if getTriPointCollision(x1, y1, x2, y2, player.x, player.y, en.x, en.y) == true then color = 11 end
    end
    line (player.x, player.y, x1, y1, color)
    line (player.x, player.y, x2, y2, color)
    line (x1, y1, x2, y2, color)
end

function drawMatrix()
    local xmod = (player.x-60)/6
    local ymod = (player.y-60)/6
    for x=-64-xmod,192-xmod,16 do
        line(x, -64, x, 192, 1)
    end
    for y=-64-ymod,192-ymod,16 do
        line(-64, y, 192, y, 1)
    end
    line(0, 0, 0, 127, 1)
    line(0, 0, 127, 0, 1)
    line(127, 127, 127, 0, 1)
    line(127, 127, 0, 127, 1)
end

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

function tan(a) return sin(a)/cos(a) end

Shape = {x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    max_dx=2,
    max_dy=2,
    acc = 0,
    friction=0.90
}

MovingGate = {x1=0,
    x2=0,
    y1=10,
    y2=0,
    centerPosX=0,
    centerPosY=0,
    angle=0,
    halfCircleSin=0,
    exploding=false,
    max_dx=0.3,
    max_dy=0.3,
    dangle=0;
}
Particle = {x=0,
    y=0,
    dx = 0,
    dy = 0,
    max_frames=30,
    friction=0.70,
    color=10,
    frames = 0
}

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

Player = Shape:new{
    sprite = 0,
    x=60,
    y=60,
    max_dx=3,
    max_dy=3,
    acc = 0.15,
    angle = 0,
    dead = false,
    color = 6
}
EasyE = Shape:new{
    x=60,
    y=60,
    max_dx=3,
    max_dy=3,
    acc = 0.10,
    friction=0.80,
    color=9,
    points=2
}
MediumE = Shape:new{
    x=60,
    y=60,
    max_dx=3,
    max_dy=3,
    acc = 0.12,
    friction=0.88,
    color=8,
    points=3
}
FastE = Shape:new{
    x=60,
    y=60,
    max_dx=15,
    max_dy=15,
    acc = 0.05,
    friction=0.78,
    color=14,
    timer=180,
    activeTime=60,
    angle=0,
    points=10
}

function getDist(x1, y1, x2, y2)
    local distx = x1 - x2
    local disty = y1 - y2
    return sqrt((distx*distx) + (disty*disty))
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
    if (area1 + area2 + area3 == areaOrig) then
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

function Shape:move()
    local diffx =  self.x - player.x
    local diffy = self.y - player.y
    local angle = atan2(diffx, diffy*-1)
    self.dx += self.acc*(cos(angle)*-1)
    self.dy += self.acc*sin(angle)
    self.dx*=self.friction
    self.dy*=self.friction
    self.x+=self.dx
    self.y+=self.dy
    if (self.x>126) then self.x=126 end
    if (self.x<2) then self.x=2 end
    if (self.y>126) then self.y=126 end
    if (self.y<2) then self.y=2 end
end

function Shape:die()
    local this = self
    for i=1,20,1 do
        local dx = rnd(6)-3
        local dy = rnd(6)-3
        local particle = Particle:new{x=this.x, y=this.y, dx = dx, dy = dy, color = this.color, max_frames= 20}
        add(particles, particle)
    end
end

function FastE:move()
    self.timer+=-1
    if (self.timer == 0) then
    end
    if (self.timer <= 0 and self.timer >= self.activeTime*-1) then
        local diffx =  self.x - player.x
        local diffy = self.y - player.y
        self.angle = atan2(diffx, diffy*-1)
        self.dx += self.acc*cos(self.angle)*-10
        self.dy += self.acc*sin(self.angle)*10
        self.dx*=self.friction
        self.dy*=self.friction
    
        self.x+=self.dx
        self.y+=self.dy
        
        if (self.x>126) then self.x=126 end
        if (self.x<2) then self.x=2 end
        if (self.y>126) then self.y=126 end
        if (self.y<2) then self.y=2 end
    elseif (self.timer < self.activeTime*-1) then
        self.timer = 180
    end
end

function moveParticles() 
    for particle in all(particles) do
        particle:moveParticle()
        if (particle.frames >= particle.max_frames) then del(particles, particle) end
    end
end
function Particle:moveParticle() 
    self.x+=(self.dx*self.friction)
    self.y+=(self.dy*self.friction)

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
    for ix=0,sw-1 do
     for iy=0,sh-1 do
      dx=ix-x0
      dy=iy-y0
      xx=flr(dx*ca-dy*sa+x0)
      yy=flr(dx*sa+dy*ca+y0)
      if (xx>=0 and xx<sw and yy>=0 and yy<=sh) then
        if (sget(sx+xx,sy+yy) != 0) then
            pset(x+ix,y+iy,sget(sx+xx,sy+yy))
        end
      end
     end
    end
   end

player = Player:new{}
enemies = {}
gates = {}
particles = {}



__gfx__
5d000000d6000000760000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d500006d6d000067670000d5d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d00d6d6d600767676005d5d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5d56d6d6d6d67676767d5d5d5d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dd6d6d6d6767676765d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5006d6d6d0067676700d5d5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d0000d6d60000767600005d5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d50000006d00000067000000d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__sfx__
4b040b00396513f6613f6712b6710e60109601006010c601086010660108601036010260100601245012450124501235012350100501005013250132501325013250132501325013250132501325013250132501
520300000040000400004001e6501765014650134500e4500b4500643004410034000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
cf060b00396533f6633d673396733865334653296531e653136530965302653006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1800000c0700c0700c0700c0700c0700c0700e070110700c0700c0700c0700c0700c0700c0700e070110701407014070140701407014070140700e0700f0701107011070110701107011070110700f0700e070
0118000000563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c64300503
931800003f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f615
d10c00201f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f100
931800003f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f605
d10c00001d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f105
2d1800001832018320183201832018320183201a3201d3201832018320183201832018320183201a3201d3202032020320203202032020320203201a3201b3201d3201d3201d3201d3201d3201d3201b3201a320
__music__
00 45464708
00 45460908
00 05460908
01 05060708
00 05060708
00 05060708
00 05060708
00 0506070b
02 0506070b

