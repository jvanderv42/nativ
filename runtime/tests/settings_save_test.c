/* Regression: failed settings saves must retain changes for a later retry.
 * Linux test harness; deliberately uses a directory that does not yet exist. */
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include "settings.h"
int main(void) {
	char temp[] = "/tmp/nativ-settings-XXXXXX";
	char *root = mkdtemp(temp);
	assert(root);
	char dir[512], path[560], contents[1024];
	snprintf(dir, sizeof dir, "%s/new", root);
	snprintf(path, sizeof path, "%s/settings.ini", dir);
	settings_load_shared(path);
	assert(settings_int("frame_rate", 60) == 60);
	assert(settings_float("sharpen", 0.35) > 0.34);
	settings_set_int("frame_rate", 120);
	assert(settings_int("frame_rate", 60) == 120);
	settings_save();  /* fopen fails: directory doesn't exist */
	assert(access(path, F_OK) != 0);
	assert(mkdir(dir, 0700) == 0);
	settings_save();  /* should retry the previous pending change */
	FILE *f = fopen(path, "r");
	assert(f);
	size_t n = fread(contents, 1, sizeof contents - 1, f);
	contents[n] = 0;
	assert(fclose(f) == 0);
	assert(strstr(contents, "frame_rate = 120") != NULL);
	assert(unlink(path) == 0);
	assert(rmdir(dir) == 0);
	assert(rmdir(root) == 0);
	puts("settings: failed-save retry passed");
	return 0;
}
