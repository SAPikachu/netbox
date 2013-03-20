/*

Superuser-exec wrapper for HTTP serves and other needs (made especially for lighttpd).
Allows programs to be run with configurable uid/gid.
Version 0.5 (2008-07-07)

For documentation on how to configure the wrapper, see the README.
Command line option -v displays version, while -V displays compile-time configuration.
These options are only available for the super user and the server admin.

Brief version history:

Vers  Date        Changes
-----------------------------------------------------------------------------------------
0.5   2008-07-07  Added proper handling of the supplementary group access list. Fixed a
                  bug with passing on return values from the child process. Added
                  compile-time configuration options to disable the CHECK_GID feature and
                  to require the target user to have a pwent (in /etc/passwd).
                  Thanks to stbuehler, hoffie and _lotek from #lighttpd for help.
0.4   2006-06-09  Added a BSD license.
0.3   2005-09-27  Changed the wrapper to stay resident and propagate SIGTERM to the
                  target. Not doing so will prevent the server from managing the target.
                  The old behaviour can be restored with a run-time option. Fixed a bug
                  in the call to execl, which could cause it to fail or crash. No
                  security risk. Added custom return codes on errors. Added some command
                  line options.
0.2   2005-09-14  Cleaned up source a bit, and added compile-time security checks. Fixed
                  a few minor issues. Compiles under C89 now (e.g. gcc -std=c89).
0.1   2005-09-08  Initial version.


License:

Copyright (c) 2008, Sune Foldager
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of
  conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of
  conditions and the following disclaimer in the documentation and/or other materials
  provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


/* Configuration. Shouldn't be changed. */

#define ENV_UID                 "UID="
#define ENV_GID                 "GID="
#define ENV_TARGET              "TARGET="
#define ENV_CHECK_GID           "CHECK_GID="
#define ENV_NON_RESIDENT        "NON_RESIDENT="
#define ENV_DEBUG               "DEBUG"

/* Return values for various errors. */

#define RC_CALLER_UID           10
#define RC_TARGET_UID           11
#define RC_TARGET_GID           12
#define RC_TARGET               13
#define RC_MISSING_CONFIG       14
#define RC_SIGNAL_HANDLER       15
#define RC_SETGID               16
#define RC_SETUID               17
#define RC_STAT                 18
#define RC_WORLD_WRITE          19
#define RC_WRONG_USER           20
#define RC_GROUP_WRITE          21
#define RC_WRONG_GROUP          22
#define RC_EXEC                 23
#define RC_BAD_OPTION           24
#define RC_CHILD_ABNORMAL_EXIT  25
#define RC_MISSING_PWENT        26


/* User configuration. */
#include "execwrap_config.h"

/* Compile-time security checks. */
#if !TARGET_MIN_UID
#error SECURITY: TARGET_MIN_UID set to 0. See README for details.
#endif
#if !TARGET_MIN_GID
#error SECURITY: TARGET_MIN_GID set to 0. See README for details.
#endif
#if DEFAULT_UID < TARGET_MIN_UID
#error SECURITY: DEFAULT_UID set to a lower value than TARGET_MIN_UID. See README for details.
#endif
#if DEFAULT_GID < TARGET_MIN_GID
#error SECURITY: DEFAULT_GID set to a lower value than TARGET_MIN_GID. See README for details.
#endif

/* Useful macro and other stuff. */
#define VERSION_STRING "ExecWrap v0.5   Copyright (c) 2008, Sune Foldager."
#define STRLEN(a) (sizeof(a)-1)

/* Shortcuts. */
#define TARGET_PATH_PREFIX_LEN  STRLEN(TARGET_PATH_PREFIX)
#define ENV_UID_LEN             STRLEN(ENV_UID)
#define ENV_GID_LEN             STRLEN(ENV_GID)
#define ENV_TARGET_LEN          STRLEN(ENV_TARGET)
#define ENV_CHECK_GID_LEN       STRLEN(ENV_CHECK_GID)
#define ENV_NON_RESIDENT_LEN    STRLEN(ENV_NON_RESIDENT)

/* Stuff we need. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <pwd.h>
#include <sys/types.h>
#include <grp.h>

#if USE_SYSLOG

# include <syslog.h>
# include <errno.h>

#else /* USE_SYSLOG */

/* this should be after all includes */
# undef SKIP
# undef openlog
# undef setlogmask
# undef syslog

# define SKIP do { } while (0)
# define openlog(...) SKIP
# define setlogmask(...) SKIP
# define syslog(...) SKIP

#endif /* USE_SYSLOG */

/* The global child PID and previous SIGTERM handler. */
int pid;
void (*oldHandler)(int);


/* SIGTERM handler. */
void sigTermHandler(int signal)
{

  /* If we're in the parent, kill the child as well. */
  if(pid) kill(pid, SIGTERM);

  /* Call the default handler. */
  oldHandler(signal);

}


/* Down to business. */
int main(int argc, char* argv[], char* envp[])
{
  openlog("execwrap", LOG_PID, LOG_AUTHPRIV);
  setlogmask(LOG_UPTO(LOG_NOTICE));

  /* Verify parent UID. Only the super user and PARENT_UID are allowed. */
  int myuid = getuid();
  if(myuid != 0 && myuid != PARENT_UID) {
    syslog(LOG_ERR, "exiting with RC_CALLER_UID, UID=%d", myuid);
    return RC_CALLER_UID;
  }

  /* Command line options. */
  if(argc > 1)
  {
    if(argv[1][0] == '-') switch(argv[1][1])
    {
      case 'v': puts(VERSION_STRING);
                return 0;
      case 'V': puts(VERSION_STRING);
                puts("Compile-time configuration:");
                printf("PARENT_UID         : %d\n", PARENT_UID);
                printf("TARGET_MIN_UID     : %d\n", TARGET_MIN_UID);
                printf("TARGET_MIN_GID     : %d\n", TARGET_MIN_GID);
                printf("TARGET_PATH_PREFIX : %s\n", TARGET_PATH_PREFIX);
                printf("DEFAULT_UID        : %d\n", DEFAULT_UID);
                printf("DEFAULT_GID        : %d\n", DEFAULT_GID);
                puts("");
                printf("REQUIRE_PWENT      : %d\n", REQUIRE_PWENT);
                printf("ALLOW_CHECKGID     : %d\n", ALLOW_CHECKGID);
                return 0;
    }

    /* Fail on unknown option. Known options return quietly above. */
    return RC_BAD_OPTION;
  }

  /* we need this check before the loop over the environment,
     as we cannot rely on it to be the first env var we find */
  if (NULL != getenv(ENV_DEBUG)) {
    setlogmask(LOG_UPTO(LOG_DEBUG));
    syslog(LOG_DEBUG, "activated debug output");
  }

  /* Grab stuff from environment, and set defaults. */
  uid_t uid = DEFAULT_UID;
  gid_t gid = DEFAULT_GID;
  char* target = 0;
  char check_gid = 0;
  char non_resident = 0;
  char** p = envp;
  char* s;
  while(NULL != (s = *p++))
  {
    /* Target UID. */
    if(!strncmp(ENV_UID, s, ENV_UID_LEN))
    {
      uid = atoi(s + ENV_UID_LEN);
      if(uid < TARGET_MIN_UID) {
        syslog(LOG_ERR, "exiting with RC_TARGET_UID, UID=%d", uid);
        return RC_TARGET_UID;
      }
      syslog(LOG_DEBUG, "target UID is %d", uid);
    }

    /* Target GID. */
    if(!strncmp(ENV_GID, s, ENV_GID_LEN))
    {
      gid = atoi(s + ENV_GID_LEN);
      if(gid < TARGET_MIN_GID) {
        syslog(LOG_ERR, "exiting with RC_TARGET_GID, GID=%d", gid);
        return RC_TARGET_GID;
      }
      syslog(LOG_DEBUG, "target GID is %d", gid);
    }

    /* Target script. */
    if(!strncmp(ENV_TARGET, s, ENV_TARGET_LEN))
    {
      target = s + ENV_TARGET_LEN;
      if((target[0] != '/') || strchr(target, '~') || strstr(target, "..") ||
        strncmp(TARGET_PATH_PREFIX, target, TARGET_PATH_PREFIX_LEN)) {
        syslog(LOG_ERR, "exiting with RC_TARGET, target=%s", target);
        return RC_TARGET;
      }
      syslog(LOG_DEBUG, "TARGET is %s", target);
    }

    /* Check GID instead of UID. */
    #if ALLOW_CHECKGID
    if(!strncmp(ENV_CHECK_GID, s, ENV_CHECK_GID_LEN))
    {
      check_gid = 1;
    }
    #endif

    /* Use non-resident wrapping style. */
    if(!strncmp(ENV_NON_RESIDENT, s, ENV_NON_RESIDENT_LEN))
    {
      non_resident = 1;
    }

  }

  /* See if we got all we need. */
  if(!target) {
    syslog(LOG_ERR, "exiting with RC_MISSING_CONFIG, no TARGET");
    return RC_MISSING_CONFIG;
  }

  /* Fetch user information from passwd. */
  struct passwd *pwent = getpwuid(uid);
  #if REQUIRE_PWENT
  if(!pwent) {
    syslog(LOG_ERR, "exiting with RC_MISSING_PWENT, pwent required by config, but not found");
    return RC_MISSING_PWENT;
  }
  #endif

  if (pwent) {
    syslog(LOG_DEBUG, "pwent found, pw_name=%s", pwent->pw_name);
  }

  /* Install the SIGTERM handler. */
  if(!non_resident)
  {
    oldHandler = signal(SIGTERM, sigTermHandler);
    if(oldHandler == SIG_ERR) return RC_SIGNAL_HANDLER;
  }

  /* Fork off (or, if we are a non-resident wrapper, just carry on). */
  if(non_resident || !(pid = fork()))
  {

    /* We're in the child. Drop privileges and set the group list. */
    if(pwent && initgroups(pwent->pw_name, gid)) {
      syslog(LOG_ERR, "exiting with RC_SETGID, initgroup failed, errno=%d", errno);
      return RC_SETGID;
    }
    if(setgid(gid)) {
      syslog(LOG_ERR, "exiting with RC_SETGID, setgid failed, errno=%d", errno);
      return RC_SETGID;
    }
    if(setuid(uid)) {
      syslog(LOG_ERR, "exiting with RC_SETUID, setuid failed, errno=%d", errno);
      return RC_SETUID;
    }

    /* Stat the target script. */
    char uid_ok = 1;
    struct stat stat_buf;
    if(stat(target, &stat_buf)) {
      syslog(LOG_ERR, "exiting with RC_STAT, stat failed, errno=%d", errno);
      return RC_STAT;
    }
    int modes = stat_buf.st_mode;

    /* Never allow world-write. */
    if(modes & S_IWOTH) {
      syslog(LOG_ERR, "exiting with RC_WORLD_WRITE, modes=%d", modes);
      return RC_WORLD_WRITE;
    }

    /* Only allow user miss-match if check_gid is set. */
    if(uid != stat_buf.st_uid)
    {
      if(!check_gid) {
        syslog(LOG_ERR, "exiting with RC_WRONG_USER");
        return RC_WRONG_USER;
      }
      uid_ok = 0;
    }

    /* If group doesn't match, don't allow group-write.
       Also, don't allow if neither user or group match. */
    if(gid != stat_buf.st_gid)
    {
      if(modes & S_IWGRP) {
        syslog(LOG_ERR, "exiting with RC_GROUP_WRITE, modes=%d", modes);
        return RC_GROUP_WRITE;
      }
      if(!uid_ok) {
        syslog(LOG_ERR, "exiting with RC_WRONG_GROUP");
        return RC_WRONG_GROUP;
      }
    }

    /* All checks passed, let's become the target! */
    syslog(LOG_NOTICE, "executing target=%s, UID=%d, GID=%d", target, uid, gid);
    execl(target, target, NULL);
    return RC_EXEC;

  }

  /* Here we're in the parent. Wait for the child to be done, and return. */
  int status;
  wait(&status);
  if(WIFEXITED(status)) return WEXITSTATUS(status);
  return RC_CHILD_ABNORMAL_EXIT;
}
