/*******************************************************************************
Begin hmac_sha1.nut
Author bodinegl
Website: https://bitbucket.org/bodinegl/implibs/src/1ba63a5aa9c1?at=master
*******************************************************************************/

function left_rotate(x, n) { 
    // this has to handle signed integers
    return (x << n) | (x >> (32 - n)) & ~((-1 >> n) << n);
}

function swap32(val) {
    return ((val & 0xFF) << 24) | ((val & 0xFF00) << 8) | ((val >>> 8) & 0xFF00) | ((val >>> 24) & 0xFF);
}
    
function sha1(message) {

    local h0 = 0x67452301;
    local h1 = 0xEFCDAB89;
    local h2 = 0x98BADCFE;
    local h3 = 0x10325476;
    local h4 = 0xC3D2E1F0;
    local mb=blob((message.len()+9+63) & ~63)
    
    local original_byte_len = message.len();
    local original_bit_len = original_byte_len * 8;
    
    foreach (val in message) {
        mb.writen(val, 'b');
    }

    mb.writen('\x80', 'b')
    
    local l = ((56 - (original_byte_len + 1)) & 63) & 63;
    while (l--) {
                mb.writen('\x00', 'b')
        }
        
    mb.writen('\x00', 'i')
    mb.writen(swap32(original_bit_len), 'i')
    
    for (local i=0;i<mb.len();i+=64) {
        local w=[]; w.resize(80);

        for(local j=0;j<16;j++) {
            local s = i + j*4;
            mb.seek(s, 'b');
            w[j] = swap32(mb.readn('i'));
        }

        for(local j=16;j<80;j++) {
            w[j] = left_rotate(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);
        }
    
        local a = h0;
        local b = h1;
        local c = h2;
        local d = h3;
        local e = h4;
    
        for(local i=0;i<80;i+=1) {
            local f=0;
            local k=0;

            if (i>=0 && i<=19) {
                f = d ^ (b & (c ^ d));
                k = 0x5A827999;
            }
            else if (i>=20 && i<= 39) {
                f = b ^ c ^ d;
                k = 0x6ED9EBA1;
            }
            else if (i>=40 && i<= 59) {
                f = (b & c) | (b & d) | (c & d) ;
                k = 0x8F1BBCDC;
            }
            else if (i>=60 && i<= 79) {
                f = b ^ c ^ d;
                k = 0xCA62C1D6;
            }
            
            local _a=a
            local _b=b
            local _c=c
            local _d=d
            local _e=e
            local _f=f
            
            a = (left_rotate(_a, 5) + _f + _e + k + w[i]) & 0xffffffff;
            b = _a;
            c = left_rotate(_b, 30);
            d = _c;
            e = _d;
        }
    
        h0 = (h0 + a) & 0xffffffff
        h1 = (h1 + b) & 0xffffffff 
        h2 = (h2 + c) & 0xffffffff
        h3 = (h3 + d) & 0xffffffff
        h4 = (h4 + e) & 0xffffffff
    }
    
    local hash = blob(20);
    hash.writen(swap32(h0),'i');
    hash.writen(swap32(h1),'i');
    hash.writen(swap32(h2),'i');
    hash.writen(swap32(h3),'i');
    hash.writen(swap32(h4),'i');

    return hash;
}

function blobxor_x5c(text) {
    local len = text.len();
    local a = blob(len)
    for (local i = 0; i < len; i++) {
        a.writen(text[i] ^ 0x5c ,'b');
    }
    
    return a;
}

function blobxor_x36(text) {
    local len = text.len();
    local a = blob(len)
    for (local i = 0; i < len; i++) {
        a.writen(text[i] ^ 0x36 ,'b');
    }

    return a;
}

function blobconcat(a,b) {
          local len = b.len();
          for(local i=0; i<len; i++) {
              a.writen(b[i],'b');
          }
          return a;
}

function blobpad(s,n) {
          local b = blob(n);
                  
          local len = s.len();    
          for(local i=0; i<len; i++) {
              b.writen(s[i],'b');
          }

          for(local i=n-s.len(); i; i--) {
             b.writen('\x00', 'b');     
          }
          return b;
}

function hmac_sha1(key, message) {

    local _key;

    if ( key.len() > 64 ) {
        _key = blobpad(sha1(key),64);
    }
    else if ( key.len() <= 64 ) {
        _key = blobpad(key,64);
    }
    
    local _ok = blobxor_x5c(_key);
    local _ik= blobxor_x36(_key);
   
    return sha1(blobconcat(_ok, sha1(blobconcat(_ik, message))));
}

// helper function
function _printhex(s) {
    local h = "";
    for(local i=0;i<s.len();i++) h+=format("%02x", s[i]);
    return h;
}
/*******************************************************************************
 End hmac_sha1.nut
*******************************************************************************/




function totp(key) {
    local t = (time()/11).tostring();
    return hmac_sha1(key, t);
    //return http.hash.hmacsha1(key, t);
}

DOOR_FLAG  <- 1;
LIGHT_FLAG <- 2;
RED_FLAG   <- 4;
GREEN_FLAG <- 8;
BLACK_FLAG <- 16;

function requestHandler(request, response) {
    // Check if there is a password in the request
    if ("p" in request.query && "c" in request.query) {
        local lp = totp("THIS IS THE SECRET");
        server.log("Got otp: " + request.query["p"] + " local otp: " + http.base64encode(lp));
        if (request.query["p"] == http.base64encode(lp)) {
            local c = request.query["c"].tointeger();
            if (c & DOOR_FLAG) device.send("door", 0);
            if (c & LIGHT_FLAG) device.send("light", 0);
            if (c & RED_FLAG) device.send("led", 1);
            else if (c & GREEN_FLAG) device.send("led", 2);
            else if (c & BLACK_FLAG) device.send("led", 0);
            response.send(200, "OK"); 
        }
        else {
            response.send(401, "Unauthorized");
        }
    }
    else {
        response.send(400, "Bad request");
    }
}

http.onrequest(requestHandler);
