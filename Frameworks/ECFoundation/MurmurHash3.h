#include "pstdint.h"

uint32_t rotl(uint32_t value, int bits);
uint32_t getblock ( const uint32_t * p, int i );
void bmix32 ( uint32_t *h1, uint32_t *k1, uint32_t *c1, uint32_t *c2 );
void MurmurHash3_x86_32  ( const void * key, int len, uint32_t seed, void * out );
