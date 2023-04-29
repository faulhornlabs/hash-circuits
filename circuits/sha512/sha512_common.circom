pragma circom 2.0.0;

//------------------------------------------------------------------------------
// index rotation function for [0..63] bit indices
//
// note: we lookup the "rotated index" in the original bit vectors, 
// so the direction is reversed!

// index lookup for left rotation
function rotIdxL(i,by) {
  return  (i >= by) ? (i - by) : (i - by + 64);
}

// index lookup for right rotation
function rotIdxR(i,by) {
  return  (i + by < 64) ? (i + by) : (i + by - 64);
}

//------------------------------------------------------------------------------
// decompose a 2-bit number into a high and a low bit

template Bits2() {
  signal input  xy;
  signal output lo;
  signal output hi;

  lo <--  xy     & 1;
  hi <-- (xy>>1) & 1;

  lo*(1-lo) === 0;
  hi*(1-hi) === 0;

  xy === 2*hi + lo;
}

//------------------------------------------------------------------------------
// XOR 3 bits together

template XOR3_v1() {
  signal input  x;
  signal input  y;
  signal input  z;
  signal output out;

  component bs = Bits2();
  bs.xy <== x + y + z;
  bs.lo ==> out;
}

template XOR3_v2() {
  signal input  x;
  signal input  y;
  signal input  z;
  signal output out;

  signal tmp <== y*z;
  out <== x * (1 - 2*y - 2*z + 4*tmp) + y + z - 2*tmp;
}

template XOR23_v2( triple_flag ) {
  signal input  x;
  signal input  y;
  signal input  z;
  signal output out;

  signal tmp;

  if (triple_flag) {
    tmp <== y*z;
    out <== x * (1 - 2*y - 2*z + 4*tmp) + y + z - 2*tmp;
  }
  else {
    // we assume z=0
    out <== x + y - 2*x*y;
  }
}

//------------------------------------------------------------------------------
// decompose an n-bit number into bits

template ToBits(n) {
  signal input  inp;
  signal output out[n];

  var sum = 0;
  for(var i=0; i<n; i++) {
    out[i] <-- (inp >> i) & 1;
    out[i] * (1-out[i]) === 0;
    sum += (1<<i) * out[i];
  }

  inp === sum;
}

//------------------------------------------------------------------------------
// decompose a 65-bit number into the low 64 bits and the remaining 1 bit

template Bits65() {
  signal input  inp;
  signal output out[64];
  signal output out_word;
  signal u;

  var sum = 0;
  for(var i=0; i<64; i++) {
    out[i] <-- (inp >> i) & 1;
    out[i] * (1-out[i]) === 0;
    sum += (1<<i) * out[i];
  }

  u <-- (inp >> 64) & 1;
  u*(1-u) === 0;

  inp === sum + (1<<64)*u;
  out_word <== sum;
}

//------------------------------------------------------------------------------
// decompose a 66-bit number into the low 64 bits and the remaining 2 bit

template Bits66() {
  signal input  inp;
  signal output out[64];
  signal output out_word;
  signal u,v;

  var sum = 0;
  for(var i=0; i<64; i++) {
    out[i] <-- (inp >> i) & 1;
    out[i] * (1-out[i]) === 0;
    sum += (1<<i) * out[i];
  }

  u <-- (inp >> 64) & 1;
  v <-- (inp >> 65) & 1;
  u*(1-u) === 0;
  v*(1-v) === 0;

  inp === sum + (1<<64)*u + (1<<65)*v;
  out_word <== sum;
}


//------------------------------------------------------------------------------
// decompose a 67-bit number into the low 64 bits and the remaining 3 bit

template Bits67() {
  signal input  inp;
  signal output out[64];
  signal output out_word;
  signal u,v,w;

  var sum = 0;
  for(var i=0; i<64; i++) {
    out[i] <-- (inp >> i) & 1;
    out[i] * (1-out[i]) === 0;
    sum += (1<<i) * out[i];
  }

  u <-- (inp >> 64) & 1;
  v <-- (inp >> 65) & 1;
  w <-- (inp >> 66) & 1;
  u*(1-u) === 0;
  v*(1-v) === 0;
  w*(1-w) === 0;

  inp === sum + (1<<64)*u + (1<<65)*v + (1<<66)*w;
  out_word <== sum;
}

//------------------------------------------------------------------------------