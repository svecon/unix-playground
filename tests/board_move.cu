// CUDA implementation of random go player
// (c) Petr Baudis <pasky@ucw.cz>  2009


// FIXME: No ko detection
/* Actually, I don't think ko detection is so important; it will mud down
   playouts somewhat, but eventually all the moves to be made except one
   ko fight are made anyway and MAX_MOVES catches the last ko. */

#include <stdio.h>
#include <stdlib.h>
#include <sys/times.h>
#include <unistd.h>

#define S 11
#define S2 S*S
#define MAX_MOVES (S2 * 2)

struct board {
#define S_NONE 0
#define S_BLACK 1
#define S_WHITE 2
#define S_EDGE 3
	int stone[S2];

	/* >0: coordinate of "group center"
	 * 0: no stone there
	 * -1: eye forbidden for black to play
	 * -2: eye forbidden for white to play
	 * -3: eye forbidden for both to play */
	int group[S2];
	int libs[S2];

	float p[S2]; /* probability of play; sum = 1 */

	int random;
	int free_spots[2]; /* free spots # for black and white */
	int to_play;
	int moves;
	int komi; /* <0 black wins, >0 white wins */
} b;


__device__ unsigned int
pm_random(unsigned int seed)
{
	unsigned long hi, lo;
	lo = 16807 * (seed & 0xffff);
	hi = 16807 * (seed >> 16);
	lo += (hi & 0x7fff) << 16;
	lo += hi >> 15;
	seed = (lo & 0x7fffffff) + (lo >> 31);
	//return ((seed & 0xffff) * max) >> 16;
	return seed;
}


#define TL (threadIdx.x - 1)
#define TR (threadIdx.x + 1)
#define TU (threadIdx.x - S)
#define TD (threadIdx.x + S)

__device__ void
dprint_board(struct board *bp)
{
#if 0
	for (int i = 0; i < S; i++) {
		int j;
		for (j = 0; j < S; j++) {
			int st = bp->stone[i * S + j];
			printf("%c ", st == S_EDGE ? '#' : st == S_WHITE ? 'O' : st == S_BLACK ? 'X' : '.');
		}
		printf(" ");
		for (j = 0; j < S; j++)
			printf("%03d ", bp->group[i * S + j]);
		printf(" ");
		for (j = 0; j < S; j++)
			printf("%02d ", bp->libs[i * S + j]);
#if 0
		for (j = 0; j < S; j++)
			printf("%1.02f ", bp->p[i * S + j]);
#endif
		printf("\n");
	}
	printf("random %d free_spots %d,%d to_play %d\n", bp->random, bp->free_spots[0], bp->free_spots[1], bp->to_play);
#endif
}

__device__ void
update_libs(struct board *bp, int delta, int except)
{
	int groups[4] = { bp->group[TU], bp->group[TL], bp->group[TR], bp->group[TD] };
	/* A loop over groups[] is somehow never unrolled and groups[] is forced to
	 local memory */
	if (groups[0] != except)
		atomicAdd(&bp->libs[groups[0]], delta);
	if (groups[1] != except && groups[1] != groups[0])
		atomicAdd(&bp->libs[groups[1]], delta);
	if (groups[2] != except && groups[2] != groups[1] && groups[2] != groups[0])
		atomicAdd(&bp->libs[groups[2]], delta);
	if (groups[3] != except && groups[3] != groups[2] && groups[3] != groups[1] && groups[3] != groups[0])
		atomicAdd(&bp->libs[groups[3]], delta);
}

__device__ void
capture_stones(struct board *bp)
{
	bp->libs[threadIdx.x] = bp->libs[bp->group[threadIdx.x]];
	if (bp->libs[threadIdx.x] == 0) {
		update_libs(bp, +1, bp->group[threadIdx.x]);
		bp->stone[threadIdx.x] = S_NONE;
		bp->group[threadIdx.x] = 0;
		atomicAdd(&bp->free_spots[0], 1);
		atomicAdd(&bp->free_spots[1], 1);
	}
}

__device__ void
survey_eye(struct board &b)
{
	int nei[4] = {TU, TL, TR, TD};
	int dnei[4] = {TU-1, TU+1, TD-1, TD+1};
	int stonecount = 0; // each bye is one direction
	/* We have to manually do bit magic, nvcc is too stupid and
	 would force stonecount[] to local memory */
#define STONECOUNT_ANY(stone) (stonecount & (0xf << ((stone) * 4)))
#define STONECOUNT(stone) ((stonecount & (0xf << ((stone) * 4))) >> ((stone) * 4))
	for (int i = 0; i < 4; i++) {
		int s = b.stone[nei[i]];
		int sc = STONECOUNT(s) + 1;
		stonecount = stonecount & ~(0xf << (s * 4)) | (sc << (s * 4));
	}
	if (STONECOUNT_ANY(S_NONE) || (STONECOUNT_ANY(S_BLACK) && STONECOUNT_ANY(S_WHITE)))
		return;
	bool is_white = STONECOUNT_ANY(S_WHITE);
	bool on_edge = STONECOUNT_ANY(S_EDGE);

	/* False eyes aren't forbidden, however. */
	/* XXX: We don't support http://senseis.xmp.net/?TwoHeadedDragon */
	stonecount = 0;
	for (int i = 0; i < 4; i++) {
		int s = b.stone[dnei[i]];
		int sc = STONECOUNT(s) + 1;
		stonecount = stonecount & ~(0xf << (s * 4)) | (sc << (s * 4));
	}
	if (on_edge + STONECOUNT(is_white ? S_BLACK : S_WHITE) > 1) {
		/* This might've been forbidden eye in past - ponnuki */
		if (b.group[threadIdx.x] < 0) {
			if ((-b.group[threadIdx.x]) & S_BLACK)
				atomicAdd(&b.free_spots[0], 1);
			if ((-b.group[threadIdx.x]) & S_WHITE)
				atomicAdd(&b.free_spots[1], 1);
			b.group[threadIdx.x] = 0;
		}
		return;
	}

	/* In case of the last liberty, the other player can play in the eye. */
	bool last_lib = (b.stone[TL] != S_EDGE ? b.libs[TL] : b.libs[TR]) < 2;
	switch (b.group[threadIdx.x]) {
		case 0:
			/* Freshly appeared eye; remove it from the relevant pools */
			if (!last_lib || !is_white)
				atomicSub(&b.free_spots[0], 1);
			if (!last_lib || is_white)
				atomicSub(&b.free_spots[1], 1);
			break;
		case -1:
			/* Formerly half-forbidden eye; if not anymore, remove it from the other player's pool */
			if (!last_lib)
				atomicSub(&b.free_spots[1], 1);
			break;
		case -2:
			if (!last_lib)
				atomicSub(&b.free_spots[0], 1);
			break;
		case -3:
			/* Formerly forbidden eye; possibly allow one player to play inside */
			if (last_lib)
				atomicAdd(&b.free_spots[1 - is_white], 1);
			break;
	}
	b.group[threadIdx.x] = last_lib ? -1 - is_white : -3;
}

__device__ void
calc_probability(struct board &b)
{
	int group = b.group[threadIdx.x];
	if (b.stone[threadIdx.x] == S_NONE
	    && (group == 0
		/* eye forbidden just for the other player */
		|| (group < 0 && !((-group) & b.to_play)))) {
		b.p[threadIdx.x] = 1.F / b.free_spots[b.to_play - 1];
	} else {
		b.p[threadIdx.x] = 0;
	}
}

__device__ void
play_one_move(struct board &b)
{
	__shared__ int group_merge_n, group_merge[4];
	__shared__ int move;

	/** Get a random number */
	if (!threadIdx.x)
		b.random = pm_random(b.random);

	/** Choose a move to play. */
	/* So-called weighted random selection; build a tree of probability
	   bounds in O(logN), then check one node per thread. We don't need
	   to bother with downsweep-reduce, our array is fairly tiny. */
	/* upbound[] is double-buffered */
	__shared__ float upbound[S2 * 2];
	int outo = 0, ino = 1;
	upbound[threadIdx.x] = b.p[threadIdx.x];
	__syncthreads();
	for (int d = 1; d < S2; d *= 2) {
		outo = 1 - outo; ino = 1 - ino;
		if (threadIdx.x >= d)
			upbound[outo * S2 + threadIdx.x] = upbound[ino * S2 + threadIdx.x] + upbound[ino * S2 + threadIdx.x - d];
		else
			upbound[outo * S2 + threadIdx.x] = upbound[ino * S2 + threadIdx.x];
		__syncthreads();
	}

	/** Place the stone */

	float p = (1 + float(b.random & 0xffff)) / 65536;
	int to_play;
	// printf("[%d] %f < %f < %f\n", threadIdx.x, threadIdx.x ? upbound[outo * S2 + threadIdx.x - 1] : -1.F, p, upbound[outo * S2 + threadIdx.x]);
	if (p <= upbound[outo * S2 + threadIdx.x] && (!threadIdx.x || upbound[outo * S2 + threadIdx.x - 1] < p)) {
		move = threadIdx.x;
		b.stone[move] = b.to_play;
		/* Take off liberty from surrounding groups */
		update_libs(&b, -1, 0);
		group_merge_n = 0;
	} else {
		to_play = b.to_play;
	}
	__syncthreads();

	/** Survey if the stone can join existing group */
	switch (move - (int)threadIdx.x) {
		case 0:
			to_play = b.to_play == S_BLACK ? S_WHITE : S_BLACK;
			// XXX: Two ifs are probably more efficient than full branch
			if (b.group[threadIdx.x] < 0) {
				/* Half-forbidden eye */
				atomicSub(&b.free_spots[b.to_play - 1], 1);
			} else {
				atomicSub(&b.free_spots[0], 1);
				atomicSub(&b.free_spots[1], 1);
			}
			b.to_play = to_play;
			b.moves++;
			// printf("Z %d\n", move);
			break;
		case -S:
		case -1:
		case 1:
		case S:
			if (b.stone[threadIdx.x] == to_play)
				group_merge[atomicAdd(&group_merge_n, 1)] = b.group[threadIdx.x];
			else if (b.stone[threadIdx.x] == S_NONE)
				atomicAdd(&b.libs[move], 1);
			break;
	}
	__syncthreads();

	/** Merge multiple groups if applicable */
	if (group_merge_n > 1) {
		if (threadIdx.x == move)
			b.group[threadIdx.x] = group_merge[0];
		else if (threadIdx.x == group_merge[0])
			b.libs[threadIdx.x] = 0;

		for (int i = 1; i < group_merge_n; i++)
			if (b.group[threadIdx.x] == group_merge[i])
				b.group[threadIdx.x] = group_merge[0];
		__syncthreads();

		/* Recalculate liberties */
		if (b.stone[threadIdx.x] == S_NONE
		    && (b.group[TU] == group_merge[0]
		        || b.group[TD] == group_merge[0]
		        || b.group[TL] == group_merge[0]
		        || b.group[TR] == group_merge[0]))
			atomicAdd(&b.libs[group_merge[0]], 1);

	/** otherwise just join the group and survey bonus libs for the group */
	} else if (group_merge_n == 1) {
		switch (move - (int)threadIdx.x) {
			case 0:
				b.group[threadIdx.x] = group_merge[0];
				break;
			case -S:
				if (b.stone[threadIdx.x] != S_NONE)
					break;
				if (b.group[TD] != group_merge[0]
				    && b.group[TL] != group_merge[0]
				    && b.group[TR] != group_merge[0])
					atomicAdd(&b.libs[group_merge[0]], 1);
				break;
			case -1:
				if (b.stone[threadIdx.x] != S_NONE)
					break;
				if (b.group[TU] != group_merge[0]
				    && b.group[TD] != group_merge[0]
				    && b.group[TR] != group_merge[0])
					atomicAdd(&b.libs[group_merge[0]], 1);
				break;
			case 1:
				if (b.stone[threadIdx.x] != S_NONE)
					break;
				if (b.group[TU] != group_merge[0]
				    && b.group[TD] != group_merge[0]
				    && b.group[TL] != group_merge[0])
					atomicAdd(&b.libs[group_merge[0]], 1);
				break;
			case S:
				if (b.stone[threadIdx.x] != S_NONE)
					break;
				if (b.group[TU] != group_merge[0]
				    && b.group[TL] != group_merge[0]
				    && b.group[TR] != group_merge[0])
					atomicAdd(&b.libs[group_merge[0]], 1);
				break;
		}

	/** or create a new group! */
	} else {
		if (threadIdx.x == move)
			b.group[threadIdx.x] = threadIdx.x;
	}

	__syncthreads();

	/* Both following capture tests propagate liberties themselves */

	/** Take out opponent's stones */
	if (b.group[threadIdx.x] > 0 && b.stone[threadIdx.x] == b.to_play) {
		capture_stones(&b);
	}
	__syncthreads();

	/** Take out our stones */
	if (b.group[threadIdx.x] > 0 && b.stone[threadIdx.x] != b.to_play) {
		capture_stones(&b);
	}
	__syncthreads();

	/** Propagate liberties */
	if (b.group[threadIdx.x] > 0) {
		b.libs[threadIdx.x] = b.libs[b.group[threadIdx.x]];
	}
	__syncthreads();

	/** Check if we are an eye */
	if (b.stone[threadIdx.x] == S_NONE) {
		survey_eye(b);
	}
	__syncthreads();

	/** Update probabilities */
	if (b.free_spots[b.to_play - 1] > 0) {
		calc_probability(b);
		__syncthreads();
	}

	if (!threadIdx.x)
		dprint_board(&b);
}

__device__ void
board2board(struct board *b1, struct board *b2)
{
	/* First thread loads global state */
	if (!threadIdx.x) {
		b2->random = b1->random;
		b2->free_spots[0] = b1->free_spots[0];
		b2->free_spots[1] = b1->free_spots[1];
		b2->to_play = b1->to_play;
		b2->moves = b1->moves;
		b2->komi = b1->komi;
	}
	/* Then each thread loads one element */
	b2->stone[threadIdx.x] = b1->stone[threadIdx.x];
	b2->group[threadIdx.x] = b1->group[threadIdx.x];
	b2->libs[threadIdx.x] = b1->libs[threadIdx.x];
	b2->p[threadIdx.x] = b1->p[threadIdx.x];
}

__device__ void
count_score(struct board &b, int &score)
{
	/* XXX: This is horribly ineffective. */
	__shared__ int black, white;
	if (!threadIdx.x) {
		black = white = 0;
	}
	__syncthreads();
	switch (b.stone[threadIdx.x]) {
		case S_BLACK: atomicAdd(&black, 1); break;
		case S_WHITE: atomicAdd(&white, 1); break;
		case S_NONE:
			if (b.stone[TL] == S_BLACK || b.stone[TR] == S_BLACK)
				atomicAdd(&black, 1);
			else
				atomicAdd(&white, 1);
			break;
	}
	__syncthreads();
	if (!threadIdx.x)
		score = b.komi + white - black;
}

__global__ void
player(struct board *gb, int *score)
{
	/** First, load board into shared memory */
	__shared__ struct board b;
	board2board(&gb[blockIdx.x], &b);

	__syncthreads();

	/** Play the game */

#if 0
	/* For device code debugging - run fixed number of iterations */
	for (int i = 0; i < 128; i++) {
#else
	while (b.moves < MAX_MOVES && b.free_spots[0] + b.free_spots[1] > 0) {
#endif
		if (b.free_spots[b.to_play - 1] > 0) {
			play_one_move(b);
		} else {
			/* pass and let the other player make a move */
			if (!threadIdx.x) {
				b.moves++;
				b.to_play = b.to_play == S_BLACK ? S_WHITE : S_BLACK;
			}
			__syncthreads();
			calc_probability(b);
			__syncthreads();
		}
	}

	/** Count score */
	count_score(b, score[blockIdx.x]);

	/** Send board back */
	board2board(&b, &gb[blockIdx.x]);
}


void
print_board(struct board *bp)
{
	for (int i = 0; i < S; i++) {
		int j;
		for (j = 0; j < S; j++) {
			int st = bp->stone[i * S + j];
			printf("%c ", st == S_EDGE ? '#' : st == S_WHITE ? 'O' : st == S_BLACK ? 'X' : '.');
		}
		printf(" ");
		for (j = 0; j < S; j++)
			printf("%03d ", bp->group[i * S + j]);
		printf(" ");
		for (j = 0; j < S; j++)
			printf("%02d ", bp->libs[i * S + j]);
#if 0
		printf(" ");
		for (j = 0; j < S; j++)
			printf("%1.02f ", bp->p[i * S + j]);
#endif
		printf("\n");
	}
	printf("random %d moves %d free_spots %d,%d to_play %d komi %d\n", bp->random, bp->moves, bp->free_spots[0], bp->free_spots[1], bp->to_play, bp->komi);
}

clock_t start_time;
void timestats(void) {
	struct tms t;
	clock_t now = times(&t);
	int u = sysconf(_SC_CLK_TCK);
	printf("TIMES: user %fs, system %fs, total %fs\n",
			(float)t.tms_utime / u,
			(float)t.tms_stime / u,
			(float)(now - start_time) / u);
}

int
main(int argc, char *argv[])
{
	if (argc < 3) {
		fprintf(stderr, "Usage: %s RANDSEED PLAYOUTS PLAYOUTSPERJOB\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	b.random = atoi(argv[1]);
	int iters = atoi(argv[2]), ppj = atoi(argv[3]);
	b.free_spots[0] = b.free_spots[1] = (S - 2) * (S - 2);
	b.moves = b.komi = 0;
	b.to_play = S_BLACK;
	for (int i = 0; i < S2; i++) {
		b.stone[i] = (i % S == 0 || i % S == S-1 || i / S == 0 || i / S == S-1) ? S_EDGE : S_NONE;
		b.group[i] = 0;
		b.libs[i] = 0;
		if (b.stone[i] == S_NONE)
			b.p[i] = 1.f / b.free_spots[b.to_play - 1];
		else
			b.p[i] = 0;
	}
	//print_board(&b);

	start_time = times(NULL);

	int score[ppj];
	struct board *gb; int *gscore;
	cudaMalloc((void**) &gb, sizeof(*gb) * ppj);
	cudaMalloc((void**) &gscore, sizeof(*gscore) * ppj);

	int black = 0, white = 0;

	for (int i = 0; i < iters; i += ppj) {
		//printf("Copying boards to GPU...\n");
		for (int j = 0; j < ppj; j++) {
			cudaMemcpy(&gb[j], &b, sizeof(b), cudaMemcpyHostToDevice);
			b.random++;
		}

		int blocks = ppj;
		int threads = S2;
		//timestats();
		//printf("Crunching...\n");
		player <<< blocks, threads >>> (gb, gscore);
		//timestats();

		//printf("Copying score back...\n");
		cudaMemcpy(&score, gscore, sizeof(*gscore) * ppj, cudaMemcpyDeviceToHost);
		for (int j = 0; j < ppj; j++)
			if (score[j] > 0)
				white++;
			else if (score[j] < 0)
				black++;
#if 0
		for (int j = 0; j < ppj; j++)
			printf("%d ", score[j]);
		printf("\n");
#endif
#if 0
		struct board b0;
		cudaMemcpy(&b0, &gb[0], sizeof(b0), cudaMemcpyDeviceToHost);
		print_board(&b0);
#endif
		//timestats();
	}

	cudaFree(gb);
	cudaFree(gscore);
	cudaThreadExit();
	timestats();
	printf("Win stats: %.4f%% for black (%d games)\n", (float)black/(black+white), black);
	return EXIT_SUCCESS;
}
