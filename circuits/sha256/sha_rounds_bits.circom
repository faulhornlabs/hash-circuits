pragma circom 2.0.0;
  
include "sha_common.circom";
include "sha_compress.circom";

//------------------------------------------------------------------------------
// NOTE: hash_bits are little-endian!

template Sha256_rounds_bits(n) {
 
  signal input  words[n];               // round words
  signal input  hash_bits[256];         // initial state
  signal output out_hash_bits[256];     // final state after n rounds (n <= 64)

  signal  a[32][n+1];
  signal  b[32][n+1];
  signal  c[32][n+1];
  signal  dd[n+1];
  signal  e[32][n+1];
  signal  f[32][n+1];
  signal  g[32][n+1];
  signal  hh[n+1];

  var round_keys[64] =
     [ 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5
     , 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174
     , 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da
     , 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967
     , 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85
     , 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070
     , 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3
     , 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
     ];

  var sum_dd = 0;
  var sum_hh = 0;
  for(var i=0; i<32; i++) {
    a[i][0] <== hash_bits [ 0*32 + i ];
    b[i][0] <== hash_bits [ 1*32 + i ];
    c[i][0] <== hash_bits [ 2*32 + i ];
    sum_dd  +=  hash_bits [ 3*32 + i ] * (1<<i);  
    e[i][0] <== hash_bits [ 4*32 + i ];
    f[i][0] <== hash_bits [ 5*32 + i ];
    g[i][0] <== hash_bits [ 6*32 + i ];
    sum_hh  +=  hash_bits [ 7*32 + i ] * (1<<i);  
  }
  dd[0] <== sum_dd;
  hh[0] <== sum_hh;

  signal hash_words[8];
  for(var j=0; j<8; j++) {
    var sum = 0;
    for(var i=0; i<32; i++) {
      sum += (1<<i) * hash_bits[ j*32 + i ];
    }
    hash_words[j] <== sum;
  }

  component compress[n];  

  for(var k=0; k<n; k++) {

    compress[k] = Sha256_compress_inner();

    compress[k].inp <== words[k];
    compress[k].key <== round_keys[k];

    for(var i=0; i<32; i++) {
      compress[k].a[i] <== a[i][k];
      compress[k].b[i] <== b[i][k];
      compress[k].c[i] <== c[i][k];
    
      compress[k].e[i] <== e[i][k];
      compress[k].f[i] <== f[i][k];
      compress[k].g[i] <== g[i][k];
    }

    compress[k].dd <== dd[k];
    compress[k].hh <== hh[k];

    for(var i=0; i<32; i++) {
      compress[k].out_a[i] ==> a[i][k+1];
      compress[k].out_b[i] ==> b[i][k+1];
      compress[k].out_c[i] ==> c[i][k+1];
    
      compress[k].out_e[i] ==> e[i][k+1];
      compress[k].out_f[i] ==> f[i][k+1];
      compress[k].out_g[i] ==> g[i][k+1];
    }

    compress[k].out_dd ==> dd[k+1];
    compress[k].out_hh ==> hh[k+1];
  }

  component modulo[8];
  for(var j=0; j<8; j++) {
    modulo[j] = Mod33();
  }

  var sum_a = 0;
  var sum_b = 0;
  var sum_c = 0;
  var sum_e = 0;
  var sum_f = 0;
  var sum_g = 0;
  for(var i=0; i<32; i++) {
    sum_a += (1<<i) * a[i][n];
    sum_b += (1<<i) * b[i][n];
    sum_c += (1<<i) * c[i][n];
    sum_e += (1<<i) * e[i][n];
    sum_f += (1<<i) * f[i][n];
    sum_g += (1<<i) * g[i][n];
  }
  
  modulo[0].inp <== hash_words[0] + sum_a;
  modulo[1].inp <== hash_words[1] + sum_b;
  modulo[2].inp <== hash_words[2] + sum_c;
  modulo[3].inp <== hash_words[3] + dd[n];
  modulo[4].inp <== hash_words[4] + sum_e;
  modulo[5].inp <== hash_words[5] + sum_f;
  modulo[6].inp <== hash_words[6] + sum_g;
  modulo[7].inp <== hash_words[7] + hh[n];

  for(var j=0; j<8; j++) {
    for(var i=0; i<32; i++) {
      modulo[j].bit[i] ==> out_hash_bits[j*32+i];
    }
  }

}

// -----------------------------------------------------------------------------
