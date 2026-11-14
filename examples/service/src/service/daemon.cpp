// daemon.cpp — POSIX daemon process with SIGTERM/SIGINT handling

#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

#include <fcntl.h>

static volatile sig_atomic_t g_running = 1;

static void signal_handler(int) {
    g_running = 0;
}

static bool daemonize() {
    switch (fork()) {
        case -1: return false;
        case 0: break;
        default: _exit(0);
    }
    if (setsid() == -1) return false;
    signal(SIGHUP, SIG_IGN);
    switch (fork()) {
        case -1: return false;
        case 0: break;
        default: _exit(0);
    }
    int dev_null = open("/dev/null", O_RDWR);
    if (dev_null >= 0) {
        dup2(dev_null, STDIN_FILENO);
        dup2(dev_null, STDOUT_FILENO);
        dup2(dev_null, STDERR_FILENO);
        if (dev_null > STDERR_FILENO) close(dev_null);
    }
    if (chdir("/") != 0) return false;
    umask(0);
    return true;
}

int main() {
    struct sigaction sa {};
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGINT, &sa, nullptr);
    signal(SIGHUP, SIG_IGN);

    if (!daemonize()) {
        fprintf(stderr, "Failed to daemonize\n");
        return 1;
    }

    while (g_running) {
        sleep(1);
    }

    return 0;
}
