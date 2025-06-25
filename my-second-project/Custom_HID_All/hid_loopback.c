#include <stdio.h>
#include <stint.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <sys/select.h>

// 正确的配置参数
#define HID_DEVICE "/dev/hidg0"  // HID gadget设备节点
#define REPORT_SIZE 65           // 报告大小 = 1字节报告ID + 64字节数据 (65字节)
#define TIMEOUT_SEC 1            // 读取超时时间(秒)

// 全局变量
volatile sig_atomic_t running = 1;

// 信号处理函数
void signal_handler(int sig) {
    running = 0;
    printf("\nSignal %d received, exiting...\n", sig);
}

// 获取当前时间字符串
const char* current_time() {
    static char buffer[20];
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(buffer, sizeof(buffer), "%H:%M:%S", tm_info);
    return buffer;
}

// 带超时的读取函数
int read_with_timeout(int fd, void *buf, size_t count, int timeout_sec) {
    fd_set set;
    struct timeval timeout;
    
    FD_ZERO(&set);
    FD_SET(fd, &set);
    
    timeout.tv_sec = timeout_sec;
    timeout.tv_usec = 0;
    
    int rv = select(fd + 1, &set, NULL, NULL, &timeout);
    if (rv == -1) {
        perror("select error");
        return -1; // 错误
    } else if (rv == 0) {
        return 0; // 超时
    }
    
    // 数据可读
    return read(fd, buf, count);
}

int main() {
    printf("[%s] HID Loopback Service Starting...\n", current_time());
    printf("[%s] Using report size: %d bytes (0x%X in hex)\n", 
           current_time(), REPORT_SIZE, REPORT_SIZE);
    
    // 设置信号处理
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // 打开HID设备
    int fd = open(HID_DEVICE, O_RDWR | O_NONBLOCK);
    if (fd < 0) {
        perror("Failed to open HID device");
        return EXIT_FAILURE;
    }
    printf("[%s] Device %s opened successfully\n", current_time(), HID_DEVICE);
    
    uint8_t buffer[REPORT_SIZE];
    ssize_t bytes_read, bytes_written;
    
    printf("[%s] Ready to receive and loopback data...\n", current_time());
    printf("[%s] Press Ctrl+C to stop\n", current_time());
    
    while (running) {
        // 清空缓冲区
        memset(buffer, 0, sizeof(buffer));
        
        // 1. 带超时读取PC数据
        bytes_read = read_with_timeout(fd, buffer, sizeof(buffer), TIMEOUT_SEC);
        
        if (bytes_read < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                // 无数据，继续等待
                continue;
            }
            perror("Read error");
            usleep(100000); // 100ms延迟后重试
            continue;
        }
        
        if (bytes_read == 0) {
            // 超时，无数据
            continue;
        }
        
        // 成功读取数据
        printf("[%s] Received %zd bytes: [ID:0x%02X] ", 
               current_time(), bytes_read, buffer[0]);
        
        // 打印前8字节数据
        for (int i = 1; i < bytes_read && i < 9; i++) {
            printf("%02X ", buffer[i]);
        }
        if (bytes_read > 9) printf("...");
        printf("\n");
        
        // 2. 添加回传标记(在数据部分)
        if (bytes_read >= 3) {
            buffer[1] = 0xCA; // Custom Acknowledge
            buffer[2] = 0xFE; // Feature Enabled
            printf("[%s] Added loopback marker: CA FE\n", current_time());
        }
        
        // 3. 立即将数据回传
        bytes_written = write(fd, buffer, sizeof(buffer));
        
        if (bytes_written < 0) {
            perror("Write error");
        } else {
            printf("[%s] Sent %zd bytes back to PC: [ID:0x%02X] ", 
                   current_time(), bytes_written, buffer[0]);
            
            // 打印前8字节数据
            for (int i = 1; i < 9 && i < bytes_written; i++) {
                printf("%02X ", buffer[i]);
            }
            if (bytes_written > 9) printf("...");
            printf("\n");
        }
    }
    
    // 清理资源
    close(fd);
    printf("[%s] Service stopped. Device closed\n", current_time());
    return EXIT_SUCCESS;
}
