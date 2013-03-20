/*

User configuration for ExecWrap. Please review ALL items in this file, before you compile.
Remember, the security of your system depends on getting these right!

See the README for documentation.

*/


/* Our parent must have this UID, or we will abort. */
#define PARENT_UID              33

/* Minimum UID we can switch to. */
#define TARGET_MIN_UID          1001

/* Minimum GID we can switch to. */
#define TARGET_MIN_GID          1001

/* Path prefix all targets must start with. */
#define TARGET_PATH_PREFIX      "/etc/sapikachu/webui/"

/* Default UID to switch to, if none given. */
#define DEFAULT_UID             65534

/* Default GID to switch to, if none given. */
#define DEFAULT_GID             65534


/* Require users to have pwents (i.e. entries in /etc/passwd or similar)? */
#define REQUIRE_PWENT           1

/* Allow use of the CHECK_GID mode? */
#define ALLOW_CHECKGID          1

/* Use syslog to report errors */
#define USE_SYSLOG              1
