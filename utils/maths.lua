function math.lerp(a,b,i) return a+((b-a)*i) end
function math.mod(n1, n2) return ((n1-1)%(n2))+1 end--index 1 mod
function math.clamp(n, min, max)
    return math.max(min<max and min or max, math.min(n, min<max and max or min))
end
function math.round(n) return math.floor(n+0.5) end

function math.easeIn(n) return math.sin(n*math.pi*0.5) end
function math.easeOut(n) return math.cos(n*math.pi*0.5) end
function math.sign(n) return n and (n==0 and 0 or n<0 and -1 or 1) end
function math.yeet(n) return 2.70158*n*n*n-1.70158*n*n end
function math.easeBothElastic(n) return n==0 and 0 or n==1 and 1 or n<0.5
    and -(math.pow(2, 20 * n - 10) * math.sin((20 * n - 11.125) * 1.3962634)) / 2
    or (math.pow(2, -20 * n + 10) * math.sin((20 * n - 11.125) * 1.3962634)) / 2 + 1
end
function math.easeOutElastic(n) return n==0 and 0 or n==1 and 1 or
    math.pow(2, -25*n) * math.sin((n*15-0.75) * 2.0943951) + 1
end
function math.easeOutBack(x, intensity)
    return 1+intensity * math.pow(x - 1, 3) + (intensity-1) * math.pow(x - 1, 2) --defaults to 2.70158
end

function math.easeDecay(a,b,d,dt) return b+(a-b)*math.exp(-d*dt) end--Like math.lerp(a,b,dt), but not framerate dependant. d is the decay factor 1-25 for slow to fast. ish
