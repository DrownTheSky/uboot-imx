# MX6ULL 14x14 EVK U-Boot启动流程分析

## 概述

本文档基于 `mx6ull_14x14_evk_defconfig` 配置文件，详细分析了MX6ULL 14x14 EVK开发板的U-Boot启动流程。

## 配置文件分析

### 主要配置项

```bash
CONFIG_ARM=y                    # ARM架构
CONFIG_ARCH_MX6=y              # i.MX6系列
CONFIG_MX6ULL=y                # MX6ULL芯片
CONFIG_TARGET_MX6ULL_14X14_EVK=y  # 目标板型
CONFIG_DEFAULT_DEVICE_TREE="imx6ull-14x14-evk"  # 默认设备树
CONFIG_BOARD_EARLY_INIT_F=y    # 启用板级早期初始化
CONFIG_BOARD_LATE_INIT=y       # 启用板级后期初始化
CONFIG_VIDEO=y                 # 启用视频支持
CONFIG_VIDEO_LOGO=y            # 启用Logo显示
CONFIG_SPLASH_SCREEN=y         # 启用启动画面
CONFIG_VIDEO_MXS=y             # 启用MXS视频驱动
```

### 启动命令配置

```bash
CONFIG_BOOTCOMMAND="run findfdt;mmc dev ${mmcdev};mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run mmcboot; else run netboot; fi; fi; else run netboot; fi"
run findfdt;
mmc dev ${mmcdev};
mmc dev ${mmcdev};
if mmc rescan; then
    if run loadbootscript; then
        run bootscript;
    else
        if run loadimage; then
            run mmcboot;
        else
            run netboot;
        fi;
    fi;
else
    run netboot;
fi
```

## 启动流程详解

### 第一阶段：board_init_f (重定位前初始化)

`board_init_f` 函数执行 `init_sequence_f` 数组中的初始化函数，这些函数在U-Boot重定位到RAM之前执行。

#### init_sequence_f 数组详细分析

```c
static const init_fnc_t init_sequence_f[] = {
    setup_mon_len,              // 1. 设置监控器长度
    fdtdec_setup,               // 2. 设备树设置
    initf_malloc,               // 3. 早期内存分配器初始化
    log_init,                   // 4. 日志系统初始化
    initf_bootstage,            // 5. 启动阶段跟踪初始化
    event_init,                 // 6. 事件系统初始化
    bloblist_maybe_init,        // 7. Bloblist初始化
    setup_spl_handoff,          // 8. SPL移交设置
    arch_cpu_init,              // 9. 架构CPU初始化
    mach_cpu_init,              // 10. 机器CPU初始化
    initf_dm,                   // 11. 设备模型初始化
    board_early_init_f,         // 12. 板级早期初始化
    timer_init,                 // 13. 定时器初始化
    env_init,                   // 14. 环境变量初始化
    init_baud_rate,             // 15. 波特率初始化
    serial_init,                // 16. 串口初始化
    console_init_f,             // 17. 控制台初始化
    display_options,            // 18. 显示选项
    display_text_info,          // 19. 显示文本信息
    checkcpu,                   // 20. CPU检查
    print_cpuinfo,              // 21. 打印CPU信息
    show_board_info,            // 22. 显示板级信息
    announce_dram_init,         // 23. 宣布DRAM初始化
    dram_init,                  // 24. DRAM初始化
    setup_dest_addr,            // 25. 设置目标地址
    reserve_pram,               // 26. 保留PRAM
    reserve_round_4k,           // 27. 4K对齐保留
    arch_reserve_mmu,           // 28. 保留MMU
    reserve_video,              // 29. 保留视频内存
    reserve_trace,              // 30. 保留跟踪内存
    reserve_uboot,              // 31. 保留U-Boot内存
    reserve_malloc,             // 32. 保留malloc内存
    reserve_board,              // 33. 保留板级内存
    reserve_global_data,        // 34. 保留全局数据
    reserve_fdt,                // 35. 保留设备树内存
    reserve_bootstage,          // 36. 保留启动阶段内存
    reserve_bloblist,           // 37. 保留bloblist内存
    reserve_arch,               // 38. 保留架构特定内存
    reserve_stacks,             // 39. 保留栈内存
    dram_init_banksize,         // 40. DRAM bank大小初始化
    show_dram_config,           // 41. 显示DRAM配置
    setup_bdinfo,               // 42. 设置板级信息
    display_new_sp,             // 43. 显示新栈指针
    reloc_fdt,                  // 44. 重定位设备树
    reloc_bootstage,            // 45. 重定位启动阶段
    reloc_bloblist,             // 46. 重定位bloblist
    setup_reloc,                // 47. 设置重定位
    clear_bss,                  // 48. 清除BSS段
    cyclic_unregister_all,      // 49. 注销所有循环函数
    jump_to_copy,               // 50. 跳转到拷贝
    NULL,
};
```

#### 各函数详细功能说明

##### 1. setup_mon_len
- **功能**: 设置U-Boot监控器的长度
- **实现**: 计算 `__bss_end - _start` 的差值
- **作用**: 为后续内存管理提供U-Boot镜像大小信息

##### 2. fdtdec_setup
- **功能**: 初始化设备树
- **实现**: 从不同来源加载设备树二进制文件
- **优先级**: bloblist > 环境变量 > 板级特定 > 分离文件 > 嵌入式
- **作用**: 为硬件配置提供设备树支持

##### 3. initf_malloc
- **功能**: 初始化早期内存分配器
- **实现**: 设置malloc基地址和限制
- **作用**: 为重定位前提供动态内存分配能力

##### 4. log_init
- **功能**: 初始化日志系统
- **实现**: 设置日志缓冲区和级别
- **作用**: 提供调试和错误信息输出功能

##### 5. initf_bootstage
- **功能**: 初始化启动阶段跟踪
- **实现**: 设置bootstage缓冲区
- **作用**: 跟踪启动过程中的各个阶段

##### 6. event_init
- **功能**: 初始化事件系统
- **实现**: 初始化事件监听器列表
- **作用**: 支持事件驱动的初始化流程

##### 7. bloblist_maybe_init
- **功能**: 可能初始化bloblist
- **实现**: 检查并初始化bloblist结构
- **作用**: 管理启动过程中的数据块

##### 8. setup_spl_handoff
- **功能**: 设置SPL移交信息
- **实现**: 从bloblist中查找SPL移交数据
- **作用**: 处理SPL到U-Boot的移交

##### 9. arch_cpu_init
- **功能**: 架构相关的CPU初始化
- **实现**: 架构特定的CPU设置
- **作用**: 初始化CPU的基本功能

##### 10. mach_cpu_init
- **功能**: 机器相关的CPU初始化
- **实现**: SoC特定的CPU设置
- **作用**: 初始化SoC相关的CPU功能

##### 11. initf_dm
- **功能**: 初始化设备模型
- **实现**: 设置设备树和驱动模型
- **作用**: 为设备驱动提供框架

##### 12. board_early_init_f
- **功能**: 板级早期初始化
- **实现**: 板级特定的早期设置
- **作用**: 初始化板级硬件

##### 13. timer_init
- **功能**: 初始化定时器
- **实现**: 设置系统定时器
- **作用**: 提供时间基准

##### 14. env_init
- **功能**: 初始化环境变量
- **实现**: 设置环境变量存储
- **作用**: 提供配置参数存储

##### 15. init_baud_rate
- **功能**: 初始化波特率
- **实现**: 设置串口波特率
- **作用**: 配置串口通信参数

##### 16. serial_init
- **功能**: 初始化串口
- **实现**: 设置串口硬件
- **作用**: 提供串口通信功能

##### 17. console_init_f
- **功能**: 初始化控制台
- **实现**: 设置控制台设备
- **作用**: 提供用户交互界面

##### 18. display_options
- **功能**: 显示选项
- **实现**: 显示U-Boot版本和编译信息
- **作用**: 提供启动信息显示

##### 19. display_text_info
- **功能**: 显示文本信息
- **实现**: 显示调试信息
- **作用**: 提供调试输出

##### 20. checkcpu
- **功能**: 检查CPU
- **实现**: 验证CPU功能
- **作用**: 确保CPU正常工作

##### 21. print_cpuinfo
- **功能**: 打印CPU信息
- **实现**: 显示CPU详细信息
- **作用**: 提供CPU状态信息

##### 22. show_board_info
- **功能**: 显示板级信息
- **实现**: 显示板级硬件信息
- **作用**: 提供硬件配置信息

##### 23. announce_dram_init
- **功能**: 宣布DRAM初始化
- **实现**: 显示DRAM初始化开始信息
- **作用**: 提供启动进度信息

##### 24. dram_init
- **功能**: DRAM初始化
- **实现**: 初始化DRAM控制器和内存
- **作用**: 配置系统内存

##### 25. setup_dest_addr
- **功能**: 设置目标地址
- **实现**: 计算重定位目标地址
- **作用**: 为重定位做准备

##### 26. reserve_pram
- **功能**: 保留PRAM
- **实现**: 为持久RAM保留空间
- **作用**: 保存持久数据

##### 27. reserve_round_4k
- **功能**: 4K对齐保留
- **实现**: 将保留区域对齐到4K边界
- **作用**: 优化内存访问

##### 28. arch_reserve_mmu
- **功能**: 保留MMU
- **实现**: 为内存管理单元保留空间
- **作用**: 支持虚拟内存管理

##### 29. reserve_video
- **功能**: 保留视频内存
- **实现**: 为视频帧缓冲区保留空间
- **作用**: 支持LCD显示

##### 30. reserve_trace
- **功能**: 保留跟踪内存
- **实现**: 为函数跟踪保留空间
- **作用**: 支持调试跟踪

##### 31. reserve_uboot
- **功能**: 保留U-Boot内存
- **实现**: 为U-Boot代码保留空间
- **作用**: 确保U-Boot完整性

##### 32. reserve_malloc
- **功能**: 保留malloc内存
- **实现**: 为动态内存分配保留空间
- **作用**: 提供内存分配服务

##### 33. reserve_board
- **功能**: 保留板级内存
- **实现**: 为板级数据保留空间
- **作用**: 保存板级配置

##### 34. reserve_global_data
- **功能**: 保留全局数据
- **实现**: 为全局数据结构保留空间
- **作用**: 保存系统状态

##### 35. reserve_fdt
- **功能**: 保留设备树内存
- **实现**: 为设备树保留空间
- **作用**: 保存硬件配置

##### 36. reserve_bootstage
- **功能**: 保留启动阶段内存
- **实现**: 为启动跟踪保留空间
- **作用**: 支持启动分析

##### 37. reserve_bloblist
- **功能**: 保留bloblist内存
- **实现**: 为数据块列表保留空间
- **作用**: 管理启动数据

##### 38. reserve_arch
- **功能**: 保留架构特定内存
- **实现**: 为架构特定功能保留空间
- **作用**: 支持架构特性

##### 39. reserve_stacks
- **功能**: 保留栈内存
- **实现**: 为函数调用栈保留空间
- **作用**: 支持函数调用

##### 40. dram_init_banksize
- **功能**: DRAM bank大小初始化
- **实现**: 设置DRAM bank大小
- **作用**: 配置内存bank

##### 41. show_dram_config
- **功能**: 显示DRAM配置
- **实现**: 显示内存配置信息
- **作用**: 提供内存信息

##### 42. setup_bdinfo
- **功能**: 设置板级信息
- **实现**: 初始化板级信息结构
- **作用**: 保存板级数据

##### 43. display_new_sp
- **功能**: 显示新栈指针
- **实现**: 显示栈指针信息
- **作用**: 提供栈信息

##### 44. reloc_fdt
- **功能**: 重定位设备树
- **实现**: 将设备树移动到新位置
- **作用**: 更新设备树地址

##### 45. reloc_bootstage
- **功能**: 重定位启动阶段
- **实现**: 将启动跟踪移动到新位置
- **作用**: 更新跟踪地址

##### 46. reloc_bloblist
- **功能**: 重定位bloblist
- **实现**: 将数据块列表移动到新位置
- **作用**: 更新数据地址

##### 47. setup_reloc
- **功能**: 设置重定位
- **实现**: 准备重定位环境
- **作用**: 完成重定位准备

##### 48. clear_bss
- **功能**: 清除BSS段
- **实现**: 清零未初始化数据段
- **作用**: 初始化静态变量

##### 49. cyclic_unregister_all
- **功能**: 注销所有循环函数
- **实现**: 清理循环函数注册
- **作用**: 准备重定位

##### 50. jump_to_copy
- **功能**: 跳转到拷贝
- **实现**: 跳转到重定位后的代码
- **作用**: 开始第二阶段初始化

### 第二阶段：board_init_r (重定位后初始化)

`board_init_r` 函数执行 `init_sequence_r` 数组中的初始化函数，这些函数在U-Boot重定位到RAM后执行。

#### init_sequence_r 数组详细分析

```c
static init_fnc_t init_sequence_r[] = {
    initr_trace,                // 1. 跟踪初始化
    initr_reloc,                // 2. 重定位完成标记
    event_init,                 // 3. 事件系统初始化
    initr_caches,               // 4. 缓存启用
    initr_reloc_global_data,    // 5. 重定位全局数据
    initr_unlock_ram_in_cache,  // 6. 解锁缓存中的RAM
    initr_barrier,              // 7. 内存屏障
    initr_malloc,               // 8. 内存分配器初始化
    log_init,                   // 9. 日志系统初始化
    initr_bootstage,            // 10. 启动阶段跟踪
    console_record_init,        // 11. 控制台记录初始化
    noncached_init,             // 12. 非缓存内存初始化
    initr_of_live,              // 13. 实时设备树初始化
    initr_dm,                   // 14. 设备模型初始化
    init_addr_map,              // 15. 地址映射初始化
    board_init,                 // 16. 板级初始化
    set_cpu_clk_info,           // 17. 设置CPU时钟信息
    efi_memory_init,            // 18. EFI内存初始化
    initr_binman,               // 19. Binman初始化
    arch_fsp_init_r,            // 20. FSP架构初始化
    initr_dm_devices,           // 21. 设备模型设备初始化
    stdio_init_tables,          // 22. 标准IO表初始化
    serial_initialize,          // 23. 串口初始化
    initr_announce,             // 24. 系统公告
    dm_announce,                // 25. 设备模型公告
    initr_watchdog,             // 26. 看门狗初始化
    arch_initr_trap,            // 27. 架构陷阱初始化
    board_early_init_r,         // 28. 板级早期初始化
    post_output_backlog,        // 29. POST输出积压
    pci_init,                   // 30. PCI初始化
    arch_early_init_r,          // 31. 架构早期初始化
    power_init_board,           // 32. 电源初始化
    initr_flash,                // 33. Flash初始化
    cpu_init_r,                 // 34. CPU初始化
    efi_init_early,             // 35. EFI早期初始化
    initr_nand,                 // 36. NAND Flash初始化
    initr_onenand,              // 37. OneNAND初始化
    initr_mmc,                  // 38. MMC/SD卡初始化
    xen_init,                   // 39. Xen初始化
    initr_pvblock,              // 40. PV块设备初始化
    initr_env,                  // 41. 环境变量初始化
    initr_malloc_bootparams,    // 42. 启动参数内存分配
    cpu_secondary_init_r,       // 43. 次CPU初始化
    mac_read_from_eeprom,       // 44. 从EEPROM读取MAC地址
    pci_init,                   // 45. PCI初始化（后期）
    stdio_add_devices,          // 46. 添加标准IO设备
    jumptable_init,             // 47. 跳转表初始化
    api_init,                   // 48. API初始化
    console_init_r,             // 49. 控制台完全初始化
    console_announce_r,         // 50. 控制台公告
    show_board_info,            // 51. 显示板级信息
    arch_misc_init,             // 52. 架构杂项初始化
    misc_init_r,                // 53. 平台杂项初始化
    kgdb_init,                  // 54. KGDB初始化
    interrupt_init,             // 55. 中断初始化
    timer_init,                 // 56. 定时器初始化
    initr_status_led,           // 57. 状态LED初始化
    board_late_init,            // 58. 板级后期初始化
    initr_fastboot_setup,       // 59. Fastboot设置
    bb_miiphy_init,             // 60. 位操作MII PHY初始化
    pci_ep_init,                // 61. PCI端点初始化
    initr_net,                  // 62. 网络初始化
    initr_post,                 // 63. POST测试初始化
    initr_mem,                  // 64. 内存初始化
    initr_avbkey,               // 65. AVB密钥初始化
    initr_tee_setup,            // 66. TEE设置
    initr_check_fastboot,       // 67. 检查Fastboot
    initr_check_spl_recovery,   // 68. 检查SPL恢复
    run_main_loop,              // 69. 运行主循环
    NULL,
};
```

#### 各函数详细功能说明

##### 1. initr_trace
- **功能**: 初始化函数跟踪系统
- **实现**: 设置跟踪缓冲区和跟踪器
- **作用**: 支持函数调用跟踪和性能分析

##### 2. initr_reloc
- **功能**: 标记重定位完成
- **实现**: 设置GD_FLG_RELOC和GD_FLG_FULL_MALLOC_INIT标志
- **作用**: 通知系统重定位已完成，可以正常使用内存分配

##### 3. event_init
- **功能**: 初始化事件系统
- **实现**: 设置事件处理框架
- **作用**: 支持事件驱动的初始化流程

##### 4. initr_caches
- **功能**: 启用CPU缓存
- **实现**: 调用enable_caches函数
- **作用**: 提高内存访问性能

##### 5. initr_reloc_global_data
- **功能**: 重定位全局数据结构
- **实现**: 更新gd指针和相关信息
- **作用**: 确保全局数据访问正确

##### 6. initr_unlock_ram_in_cache
- **功能**: 解锁缓存中的RAM区域
- **实现**: 调用unlock_ram_in_cache函数
- **作用**: 允许对RAM区域的缓存访问

##### 7. initr_barrier
- **功能**: 设置内存屏障
- **实现**: 确保内存操作顺序
- **作用**: 保证内存一致性

##### 8. initr_malloc
- **功能**: 初始化完整的内存分配器
- **实现**: 设置malloc堆和分配器
- **作用**: 提供动态内存分配服务

##### 9. log_init
- **功能**: 初始化日志系统
- **实现**: 设置日志级别和输出
- **作用**: 提供调试和错误日志

##### 10. initr_bootstage
- **功能**: 初始化启动阶段跟踪
- **实现**: 设置bootstage跟踪器
- **作用**: 记录启动时间和性能

##### 11. console_record_init
- **功能**: 初始化控制台记录
- **实现**: 设置控制台记录缓冲区
- **作用**: 记录控制台输出

##### 12. noncached_init
- **功能**: 初始化非缓存内存区域
- **实现**: 设置非缓存内存池
- **作用**: 为DMA等操作提供非缓存内存

##### 13. initr_of_live
- **功能**: 初始化实时设备树
- **实现**: 构建实时设备树结构
- **作用**: 支持动态设备树操作

##### 14. initr_dm
- **功能**: 初始化设备模型框架
- **实现**: 调用dm_init_and_scan
- **作用**: 建立设备驱动管理框架

##### 15. init_addr_map
- **功能**: 初始化地址映射
- **实现**: 设置虚拟地址映射
- **作用**: 支持虚拟内存管理

##### 16. board_init
- **功能**: 板级特定的初始化
- **实现**: 调用board_init函数
- **作用**: 初始化板级硬件

##### 17. set_cpu_clk_info
- **功能**: 设置CPU时钟信息
- **实现**: 获取并设置时钟频率
- **作用**: 为系统提供时钟信息

##### 18. efi_memory_init
- **功能**: 初始化EFI内存
- **实现**: 设置EFI内存映射
- **作用**: 支持EFI启动

##### 19. initr_binman
- **功能**: 初始化Binman工具
- **实现**: 设置镜像构建工具
- **作用**: 支持镜像构建

##### 20. arch_fsp_init_r
- **功能**: 初始化FSP架构
- **实现**: 调用FSP初始化函数
- **作用**: 支持FSP固件

##### 21. initr_dm_devices
- **功能**: 初始化设备模型中的设备
- **实现**: 扫描并绑定设备
- **作用**: 建立设备驱动框架

##### 22. stdio_init_tables
- **功能**: 初始化标准IO表
- **实现**: 设置标准输入输出设备
- **作用**: 提供标准IO服务

##### 23. serial_initialize
- **功能**: 初始化串口设备
- **实现**: 扫描并初始化串口
- **作用**: 提供串口通信

##### 24. initr_announce
- **功能**: 显示系统启动信息
- **实现**: 打印启动横幅和版本信息
- **作用**: 确认系统启动状态

##### 25. dm_announce
- **功能**: 显示设备模型信息
- **实现**: 打印设备和uclass统计
- **作用**: 显示设备初始化状态

##### 26. initr_watchdog
- **功能**: 初始化看门狗定时器
- **实现**: 设置看门狗配置
- **作用**: 提供系统监控

##### 27. arch_initr_trap
- **功能**: 初始化架构特定的陷阱
- **实现**: 设置异常处理
- **作用**: 处理系统异常

##### 28. board_early_init_r
- **功能**: 板级特定的早期初始化
- **实现**: 调用board_early_init_r
- **作用**: 初始化板级硬件

##### 29. post_output_backlog
- **功能**: 输出POST积压信息
- **实现**: 显示POST测试结果
- **作用**: 显示硬件自检结果

##### 30. pci_init
- **功能**: 初始化PCI总线
- **实现**: 扫描PCI设备
- **作用**: 支持PCI设备

##### 31. arch_early_init_r
- **功能**: 架构特定的早期初始化
- **实现**: 调用arch_early_init_r
- **作用**: 初始化架构特定功能

##### 32. power_init_board
- **功能**: 初始化电源管理
- **实现**: 设置电源配置
- **作用**: 管理电源状态

##### 33. initr_flash
- **功能**: 初始化Flash设备
- **实现**: 扫描并初始化Flash
- **作用**: 提供Flash存储访问

##### 34. cpu_init_r
- **功能**: CPU特定的初始化
- **实现**: 调用cpu_init_r
- **作用**: 初始化CPU功能

##### 35. efi_init_early
- **功能**: EFI早期初始化
- **实现**: 设置EFI环境
- **作用**: 支持EFI启动

##### 36. initr_nand
- **功能**: 初始化NAND Flash
- **实现**: 扫描并初始化NAND
- **作用**: 提供NAND存储访问

##### 37. initr_onenand
- **功能**: 初始化OneNAND Flash
- **实现**: 扫描并初始化OneNAND
- **作用**: 提供OneNAND存储访问

##### 38. initr_mmc
- **功能**: 初始化MMC/SD卡
- **实现**: 扫描并初始化MMC设备
- **作用**: 提供MMC存储访问

##### 39. xen_init
- **功能**: 初始化Xen虚拟化
- **实现**: 设置Xen环境
- **作用**: 支持Xen虚拟化

##### 40. initr_pvblock
- **功能**: 初始化PV块设备
- **实现**: 设置PV块设备
- **作用**: 支持PV存储

##### 41. initr_env
- **功能**: 初始化环境变量
- **实现**: 从存储设备加载环境变量
- **作用**: 设置系统配置

##### 42. initr_malloc_bootparams
- **功能**: 为启动参数分配内存
- **实现**: 分配启动参数空间
- **作用**: 保存启动参数

##### 43. cpu_secondary_init_r
- **功能**: 初始化次CPU
- **实现**: 调用cpu_secondary_init_r
- **作用**: 支持多核CPU

##### 44. mac_read_from_eeprom
- **功能**: 从EEPROM读取MAC地址
- **实现**: 读取并设置MAC地址
- **作用**: 设置网络设备地址

##### 45. pci_init (后期)
- **功能**: 后期PCI初始化
- **实现**: 完成PCI设备初始化
- **作用**: 确保PCI设备正常工作

##### 46. stdio_add_devices
- **功能**: 添加标准IO设备
- **实现**: 注册标准IO设备
- **作用**: 扩展IO设备支持

##### 47. jumptable_init
- **功能**: 初始化跳转表
- **实现**: 设置函数跳转表
- **作用**: 支持动态函数调用

##### 48. api_init
- **功能**: 初始化API系统
- **实现**: 设置API框架
- **作用**: 提供应用程序接口

##### 49. console_init_r
- **功能**: 完全初始化控制台
- **实现**: 设置控制台设备
- **作用**: 提供完整的控制台服务

##### 50. console_announce_r
- **功能**: 显示控制台信息
- **实现**: 打印控制台配置
- **作用**: 确认控制台状态

##### 51. show_board_info
- **功能**: 显示详细的板级信息
- **实现**: 打印硬件配置信息
- **作用**: 提供硬件信息

##### 52. arch_misc_init
- **功能**: 架构特定的杂项初始化
- **实现**: 调用arch_misc_init
- **作用**: 初始化架构特定功能

##### 53. misc_init_r
- **功能**: 平台特定的杂项初始化
- **实现**: 调用misc_init_r
- **作用**: 初始化平台特定功能

##### 54. kgdb_init
- **功能**: 初始化KGDB调试器
- **实现**: 设置KGDB环境
- **作用**: 提供内核调试支持

##### 55. interrupt_init
- **功能**: 初始化中断系统
- **实现**: 设置中断控制器
- **作用**: 提供中断处理

##### 56. timer_init
- **功能**: 初始化系统定时器
- **实现**: 设置定时器设备
- **作用**: 提供时间服务

##### 57. initr_status_led
- **功能**: 初始化状态LED
- **实现**: 设置LED控制
- **作用**: 提供状态指示

##### 58. board_late_init
- **功能**: 板级特定的后期初始化
- **实现**: 调用board_late_init
- **作用**: 完成板级初始化

##### 59. initr_fastboot_setup
- **功能**: 设置Fastboot功能
- **实现**: 初始化Fastboot环境
- **作用**: 支持快速启动

##### 60. bb_miiphy_init
- **功能**: 初始化位操作MII PHY
- **实现**: 设置MII PHY接口
- **作用**: 支持网络PHY控制

##### 61. pci_ep_init
- **功能**: 初始化PCI端点
- **实现**: 设置PCI端点设备
- **作用**: 支持PCI通信

##### 62. initr_net
- **功能**: 初始化网络系统
- **实现**: 调用eth_initialize
- **作用**: 提供网络通信

##### 63. initr_post
- **功能**: 初始化POST测试
- **实现**: 运行POST测试
- **作用**: 验证硬件功能

##### 64. initr_mem
- **功能**: 初始化内存管理
- **实现**: 设置内存参数
- **作用**: 完成内存配置

##### 65. initr_avbkey
- **功能**: 初始化AVB密钥
- **实现**: 设置AVB密钥
- **作用**: 支持Android验证启动

##### 66. initr_tee_setup
- **功能**: 设置可信执行环境
- **实现**: 初始化TEE
- **作用**: 支持安全功能

##### 67. initr_check_fastboot
- **功能**: 检查Fastboot状态
- **实现**: 验证Fastboot配置
- **作用**: 确保Fastboot正常

##### 68. initr_check_spl_recovery
- **功能**: 检查SPL恢复模式
- **实现**: 验证SPL恢复配置
- **作用**: 支持系统恢复

##### 69. run_main_loop
- **功能**: 进入主循环
- **实现**: 启动命令处理循环
- **作用**: 提供用户交互

## LCD显示初始化

### LCD设置函数

在 `board/freescale/mx6ullevk/mx6ullevk.c` 中：

```c
int board_late_init(void)
{
    // LCD初始化
    setup_lcd();

    // 其他初始化...
    return 0;
}
```

### 设备树LCD配置

在 `arch/arm/dts/imx6ul-14x14-evk.dtsi` 中：

```dts
&lcdif {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_lcdif_dat
                 &pinctrl_lcdif_ctrl>;
    display = <&display0>;
    status = "okay";

    display0: display {
        bits-per-pixel = <16>;
        bus-width = <24>;

        display-timings {
            native-mode = <&timing0>;
            timing0: timing0 {
                clock-frequency = <33500000>;
                hactive = <800>;
                vactive = <480>;
                hfront-porch = <40>;
                hsync-len = <128>;
                hback-porch = <88>;
                vfront-porch = <1>;
                vsync-len = <4>;
                vback-porch = <23>;
                hsync-active = <0>;
                vsync-active = <0>;
                de-active = <1>;
                pixelclk-active = <0>;
            };
        };
    };
};
```

### 启动画面显示流程

1. **LCD控制器初始化**: 配置LCDIF控制器
2. **时序设置**: 配置显示时序参数
3. **帧缓冲区设置**: 分配和配置帧缓冲区
4. **Logo显示**: 显示U-Boot Logo
5. **启动画面**: 显示自定义启动画面

## 外设初始化

### 以太网 (FEC) 初始化

```c
// 在设备树中配置
&fec1 {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_enet1>;
    phy-mode = "rmii";
    phy-handle = <&ethphy0>;
    status = "okay";
};
```

### QSPI Flash 初始化

```c
// 在设备树中配置
&qspi {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_qspi>;
    status = "okay";
    flash0: n25q256a@0 {
        reg = <0>;
        spi-max-frequency = <29000000>;
        spi-nor,ddr-quad-read-dummy = <6>;
    };
};
```

### NAND Flash 初始化

```c
// 在设备树中配置
&gpmi {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_gpmi_nand>;
    status = "okay";
    nand-on-flash-bbt;
};
```

## 启动命令和环境变量

### 默认启动命令

```bash
CONFIG_BOOTCOMMAND="run findfdt;mmc dev ${mmcdev};mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run mmcboot; else run netboot; fi; fi; else run netboot; fi"
```

### 启动流程步骤

1. **findfdt**: 查找设备树文件
2. **mmc dev**: 选择MMC设备
3. **mmc rescan**: 重新扫描MMC设备
4. **loadbootscript**: 加载启动脚本
5. **bootscript**: 执行启动脚本
6. **loadimage**: 加载内核镜像
7. **mmcboot**: 从MMC启动
8. **netboot**: 从网络启动

### 环境变量

```bash
# 启动相关
bootdelay=3
baudrate=115200
bootcmd=run findfdt;mmc dev ${mmcdev};mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadimage; then run mmcboot; else run netboot; fi; fi; else run netboot; fi

# 网络相关
ipaddr=192.168.1.100
serverip=192.168.1.1
netmask=255.255.255.0
gatewayip=192.168.1.1

# 文件系统相关
root=/dev/mmcblk0p2
rootfstype=ext4
```

## 关键文件

### 配置文件
- `configs/mx6ull_14x14_evk_defconfig`: 主配置文件
- `arch/arm/dts/imx6ull-14x14-evk.dts`: 设备树文件
- `arch/arm/dts/imx6ul-14x14-evk.dtsi`: 设备树包含文件

### 源代码文件
- `board/freescale/mx6ullevk/mx6ullevk.c`: 板级初始化代码
- `common/board_f.c`: 重定位前初始化
- `common/board_r.c`: 重定位后初始化
- `arch/arm/lib/board.c`: ARM架构板级代码

### 驱动文件
- `drivers/video/mxs.c`: MXS视频驱动
- `drivers/net/fec_mxc.c`: FEC以太网驱动
- `drivers/mtd/spi/spi_flash.c`: SPI Flash驱动

## 启动时序图

```
系统上电
    ↓
ROM代码执行
    ↓
SPL加载和初始化
    ↓
U-Boot第一阶段 (board_init_f)
    ├── 基础初始化 (1-8)
    ├── CPU和架构初始化 (9-12)
    ├── 通信初始化 (13-17)
    ├── 信息显示 (18-22)
    ├── 内存管理 (23-41)
    └── 重定位准备 (42-50)
    ↓
代码重定位到RAM
    ↓
U-Boot第二阶段 (board_init_r)
    ├── 基础重定位 (1-10)
    ├── 设备模型初始化 (11-20)
    ├── 设备初始化 (21-35)
    ├── 存储设备初始化 (36-45)
    ├── 系统服务初始化 (46-60)
    └── 网络和通信初始化 (61-69)
    ↓
主循环 (main_loop)
    ↓
等待用户输入或自动启动
```

## 调试和故障排除

### 常见问题

1. **LCD不显示**
   - 检查设备树LCD配置
   - 验证LCD时序参数
   - 确认LCD电源和背光

2. **网络不工作**
   - 检查PHY地址配置
   - 验证网络时序
   - 确认网络引脚配置

3. **启动失败**
   - 检查启动命令配置
   - 验证镜像文件完整性
   - 确认存储设备状态

### 调试命令

```bash
# 查看板级信息
bdinfo

# 查看环境变量
printenv

# 查看设备树
fdt print

# 测试网络
ping 192.168.1.1

# 查看内存信息
md 0x80000000

# 查看LCD信息
video info
```

### 日志分析

```bash
# 启用详细日志
setenv bootdelay 3
setenv debug 1

# 查看启动日志
dmesg

# 查看错误信息
log show
```

## 总结

MX6ULL 14x14 EVK的U-Boot启动流程分为两个主要阶段：

1. **第一阶段 (board_init_f)**: 在Flash中执行，完成基础初始化、内存配置和重定位准备
2. **第二阶段 (board_init_r)**: 在RAM中执行，完成设备初始化、外设配置和系统服务启动

整个启动过程包含约119个初始化函数，涵盖了从硬件初始化到用户交互的各个方面。通过合理的配置和调试，可以确保系统稳定启动并正常工作。
