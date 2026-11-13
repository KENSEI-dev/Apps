import math
def haversine_m(lat1, lng1, lat2, lng2):
    R=6371000
    p1,p2=math.radians(lat1), math.radians(lat2)
    dp=math.radians(lat2 - lat1)
    d1=math.radians(lng2 -lng1)
    a=math.sin(dp/2)**2+math.cos(p2)*math.cos(p2)*math.sin(d1/2)**2
    return 2*R*math.asin(math.sqrt(a))