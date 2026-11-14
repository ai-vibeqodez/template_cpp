// module.c — Linux kernel module

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>

static int __init __PROJECT_NAME___init(void) {
    pr_info("__PROJECT_NAME__: loading module\n");
    return 0;
}

static void __exit __PROJECT_NAME___exit(void) {
    pr_info("__PROJECT_NAME__: unloading module\n");
}

module_init(__PROJECT_NAME___init);
module_exit(__PROJECT_NAME___exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A __PROJECT_NAME__ kernel module");
MODULE_VERSION("1.0.0");
MODULE_ALIAS("__PROJECT_NAME__");
