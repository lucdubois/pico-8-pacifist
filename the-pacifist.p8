pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

xmod=0
ymod=0
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
    bigGates=0
}

function _init()
    save('@clip')
    offset = 0
    shaking = false
    shake_timer=10
    score=0
    multiplier=1
    music(0)
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
        bigGates=0
    }
    fieldpus = {}
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

function useBomb()
    if (bombs > 0 and justDied == 0) then
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
        if justDied > 0 then
            justDied -= 1
        end

        xmod = (p.x-60)/6
        ymod = (p.y-60)/6

        p.dx*=p.friction
        p.dy*=p.friction
        local angle = p.angle%360
        if (btn(0)) then 
            p.dx-=p.acc
            spawnTrail(p, 4)
            if angle > 180 then p.angle-=10 end
            if angle < 180 then p.angle+=10 end
        end -- left
        if (btn(1)) then 
            p.dx+=p.acc
            spawnTrail(p, 4)
            if angle != 0 then
                if angle > 180 then p.angle+=10 end
                if angle <= 180 then p.angle-=10 end
            end
        end -- right
        if (btn(2)) then 
            p.dy-=p.acc
            spawnTrail(p, 4)
            if ((angle <= 90 and angle >= 0) or angle > 270 ) then p.angle-=10 end
            if ((angle > 90 and angle <= 180) or (angle < 270 and angle >180)) then p.angle+=10 end
        end -- up
        if (btn(3)) then 
            p.dy+=p.acc
            spawnTrail(p, 4)
            if ((angle < 90 and angle >= 0) or angle > 270 ) then p.angle+=10 end
            if (angle > 90 or (angle < 270 and angle >=180)) then p.angle-=10 end
        end -- down

        -- if angle == 0 then p.angle = 0 end
        p.dx=mid(-p.max_dx,p.dx,p.max_dx)
        p.dy=mid(-p.max_dy,p.dy,p.max_dy)

        p.x+=p.dx
        p.y+=p.dy
        if (p.x>124) then p.x=124 end
        if (p.x<4) then p.x=4 end
        if (p.y>124) then p.y=124 end
        if (p.y<4) then p.y=4 end
        
    if (bombInUse == false) then
        if (bombRechargeT == 0 and bombs == 0) then bombs+=1 end
        if (bombRechargeT >0) then bombRechargeT-=1 end
        if (btn(4)) then
            useBomb()
        end
        if (p.dead == true and shake_timer == 0 and bombInUse == false) then
            for i=1,40,1 do
                local dx = rnd(2)-1+p.dx
                local dy = rnd(2)-1+p.dy
                local particle = Particle:new{x=p.x, y=p.y, dx = dx, dy = dy, color = 7, max_frames= 60}
                add(particles, particle)
            end
            justDied = 20
            if lives>=2 then 
                newRound()
            else
                resetGame()
            end
            
        end
        gtms+=1
        local gt = gtms/60
        if shake_timer == 0 then
            shaking = false
            shake_timer = 10
            offset=0
        end
        if shaking == true then 
            shake_timer-=1 
            offset=0.1
        end
        if bombTimer == 0 then 
            bombInUse = false
            bombTimer = 60
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
        if (gt > 120 and gt % 8 == 0) then
            local en = FastE:new{}
            spawnEnemy(en)
        elseif (gt > 30 and gt % 16 == 0) then
            local en = FastE:new{}
            spawnEnemy(en)
        end

        if gt % 2 == 0 then
            local pu = BigGatesPU:new{}
            pu:spawn()
            add(fieldpus, pu)
        end

        if (gt % (5-powerUps.moreGates) == 0) then
            local gate = MovingGate:new{}
            local bigGatesPU = powerUps.bigGates*2
            printh(bigGatesPU, 'debug.txt')
            gate.angle = rnd(0.5)+0.5;
            local s = sin(gate.angle);
            gate.cx = rnd(116);
            gate.cy = rnd(116);
            gate.x1 = gate.cx+((10+bigGatesPU)*s);
            gate.x2 = gate.cx+((-10-bigGatesPU)*s);
            gate.y1 = gate.cy+((10+bigGatesPU)*(1-s));
            gate.y2 = gate.cy+((-10-bigGatesPU)*(1-s));
            gate.dx = rnd(gate.max_dx)
            gate.dy = rnd(gate.max_dy)
            gate.dangle = rnd(0.012)-0.006
            add(gates, gate)
        end

        for pu in all(fieldpus) do
            if (pu.x-xmod < p.x and 15+pu.x-xmod > p.x and pu.y-ymod < p.y and 15+pu.y-ymod > p.y) then
                pu.catch()
                del(fieldpus, pu)
            end
        end

        for gate in all(gates) do
            local bigGatesPU = powerUps.bigGates*3
            gate.cx+=gate.dx
            gate.cy+=gate.dy
            gate.angle+=gate.dangle
            if (gate.angle>=1) then gate.angle-=1 end
            local gateSin = sin(gate.angle)
            local gateCos = cos(gate.angle)
            gate.x1 = gate.cx+((10+bigGatesPU)*gateSin);
            gate.x2 = gate.cx+((-10-bigGatesPU)*gateSin);
            gate.y1 = gate.cy+((10+bigGatesPU)*gateCos);
            gate.y2 = gate.cy+((-10-bigGatesPU)*gateCos);
            
            if (gate.cx>120 or gate.cx<0) then gate.dx*=-1 end
            if (gate.cy>120 or gate.cy<0) then gate.dy*=-1 end
            
            if (getPointCircleCollision(gate.x1, gate.y1, p.x, p.y, 2) or getPointCircleCollision(gate.x2, gate.y2, p.x, p.y, 2) ) then 
                p.dx = p.dx*-1
                p.dy = p.dy*-1
            elseif (isTouchingPlayer(gate.x1, gate.y1, gate.x2, gate.y2, p.x, p.y)) then
                local soundPlayed = false
                local enemiesKilled = 0
                for enemy in all(enemies) do
                    if (getPointCircleCollision(enemy.x, enemy.y, gate.cx, gate.cy, 40+(bigGatesPU)) == true) then
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
                    local particle = Particle:new{x=gate.cx, y=gate.cy, dx = dx, dy = dy}
                    add(particles, particle)
                end
                del(gates, gate)
                multiplier+=enemiesKilled
                bombRechargeT-=120
            end
        end
        for enemy in all(enemies) do
            enemy:move()
            if (getPointCircleCollision(enemy.x, enemy.y, p.x, p.y, 2) == true and bombInUse == false) then
                shaking = true
                sfx(2)
                p.dead = true
                for enemy2 in all(enemies) do 
                    enemy2:die() 
                    del(enemies, enemy2)
                end
            end

        end
        moveParticles()
    else 
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
            if (g.cx > 140 or g.cy > 140) then del(gates, g) end
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
end

function _draw()
    palt(0, false)
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

    for fieldpu in all(fieldpus) do
        fieldpu:draw()
    end
    for gate in all(gates) do
        circ(gate.cx, gate.cy, 40+(powerUps.bigGates*3), 1)
    end
    for gate in all(gates) do
        circfill(gate.x1,gate.y1,1,10)
        circfill(gate.x2,gate.y2,1,10)
        line(gate.x1, gate.y1, gate.x2, gate.y2, 11)
    end
    spr_r(lives-1, p.x-4, p.y-4, p.angle, 1, 1)
    for enemy in all(enemies) do
		enemy:draw()
    end
    for particle in all(particles) do
        rectfill(particle.x, particle.y, particle.x, particle.y, particle.color)
        particle.frames+=1
    end
    drawBombBar()
    drawMessage()
end

function drawTriangle()
    local pa = p.angle-90%360
    local angle1 = (pa-30)/360
    local angle2 = (pa+30)/360
    local x1 = (sin(angle1)*100)+p.x
    local y1 = (cos(angle1)*100)+p.y
    local x2 = (sin(angle2)*100)+p.x
    local y2 = (cos(angle2)*100)+p.y
    local color = 1
    for en in all(enemies) do
        if getTriPointCollision(x1, y1, x2, y2, p.x, p.y, en.x, en.y) == true then color = 11 end
    end
    line (p.x, p.y, x1, y1, color)
    line (p.x, p.y, x2, y2, color)
    line (x1, y1, x2, y2, color)
end

function drawMatrix()
    rectfill(-20, -20, 148, 148, 0)
    local newMod = 0
    if (bombInUse == true) then
        --if (bombTimer < 40) then
        newMod = ((cos((bombTimer/120))*32)+32)/64
        --end
        for x=0-xmod,128-xmod,16 do
            line(x*newMod, 0*newMod, x*newMod, 160*newMod, 1)
        end
        for y=0-ymod,128-ymod,16 do
            line(0*newMod, y*newMod, 160*newMod, y*newMod, 1)
        end
        xmod = 0
        ymod=0
    end
    for x=-64-xmod,192-xmod,16 do
        line(x*bombScale, -64, x*bombScale, 192, 1)
    end
    for y=-64-ymod,192-ymod,16 do
        line(-64, y*bombScale, 192, y*bombScale, 1)
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


function drawBombBar()
    local bombMeterW = ((5400-bombRechargeT)/5400)*127
    line(0, 127, bombMeterW , 127, 12)
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
    cx=0,
    cy=0,
    angle=0,
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

PowerUp = {x=0,
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

MoreGatesPU = PowerUp:new{
    sprite=16
}

BigGatesPU = PowerUp:new{
    sprite=17
}

Player = Shape:new{
    sprite = 0,
    x=64,
    y=64,
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
    colors={14, 7},
    timer=180,
    activeTime=60,
    angle=0,
    points=10,
    signaling=false,
    cr=0,
    crd=0.5
}

function PowerUp:spawn()
    self.x = flr(rnd(8))*16
    self.y = flr(rnd(8))*16
end

function PowerUp:draw()
    rectfill(self.x-xmod, self.y-ymod, 15+self.x-xmod, 15+self.y-ymod, 1)
    spr(self.sprite, 4+self.x-xmod, 4+self.y-ymod)
end

function MoreGatesPU:catch()
    powerUps.moreGates+=1
end

function BigGatesPU:catch()
    powerUps.bigGates+=1
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

function Shape:move()
    local diffx =  self.x - p.x
    local diffy = self.y - p.y
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
        local dx = rnd(6)-3+this.dx
        local dy = rnd(6)-3+this.dy
        local particle = Particle:new{x=this.x, y=this.y, dx = dx, dy = dy, color = this.color, max_frames= 20}
        add(particles, particle)
    end
end

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
        else self.color = self.colors[1] end
    end
    if (self.timer <= 0 and self.timer >= self.activeTime*-1) then
        local diffx =  self.x - p.x
        local diffy = self.y - p.y
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

p = Player:new{}
enemies = {}
gates = {}
particles = {}
fieldpus = {}



__gfx__
5d000000d6000000760000005d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d500006d6d000067670000d5d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d00d6d6d600767676005d5d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5d56d6d6d6d67676767d5d5d5d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dd6d6d6d6767676765d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5006d6d6d0067676700d5d5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d0000d6d60000767600005d5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d50000006d00000067000000d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44000000440000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43000050433005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300555033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030050003330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003000000333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000300000033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000034000003340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000044000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
4a040500396513f6613f6712b6710e60109601006010c601086010660108601036010260100601245012450124501235012350100501005013250132501325013250132501325013250132501325013250132501
52040000376503e6503e650356501c65014650134500e4500b4500643004410034000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
ce060b00396533f6633d673396733865334653296531e653136530965302653006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
000c01002b3302a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
340400003f7333e7233e7233d7233c7233b7233772333723337232c7232972326723237231e7231972315733107330d7330a74308743077430574303743037430374302743017430074300743007430270300703
1d1800000c0700c0700c0700c0700c0700c0700e070110700c0700c0700c0700c0700c0700c0700e070110701407014070140701407014070140700e0700f0701107011070110701107011070110700f0700e070
0118000000563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c6430050300563005030c6430050324600005630c64300503
931800003f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f6153f615
d10c00201f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f1001f1251e1001f1251f1251f1251f1001f1251f100
931800003f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f6053f6053f6053f6153f605
d10c00001d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f1051d1251e1051d1251d1251d1251f1051d1251f105
2d1800001832018320183201832018320183201a3201d3201832018320183201832018320183201a3201d3202032020320203202032020320203201a3201b3201d3201d3201d3201d3201d3201d3201b3201a320
a410000008565005052e5050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
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

