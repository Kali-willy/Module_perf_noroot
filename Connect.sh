#!/system/bin/sh
# =========================================
# Android Performance Optimizer
# For Non-Rooted Devices (ADB/Shell)
# Android 9+ Compatible
# =========================================

clear

echo "========================================="
echo "  Android Performance Optimizer v1.0"
echo "========================================="

# Get device info
DEVICE_MODEL=$(getprop ro.product.model)
ANDROID_VER=$(getprop ro.build.version.release)
BATTERY_LEVEL=$(dumpsys battery | grep level | awk '{print $2}')
SDK_VER=$(getprop ro.build.version.sdk)

echo "Device: $DEVICE_MODEL"
echo "Android: $ANDROID_VER (SDK $SDK_VER)"
echo "Battery: ${BATTERY_LEVEL}%"
echo "========================================="

# Function to set performance profile based on battery
set_performance_profile() {
    BAT=$1
    
    if [ $BAT -le 20 ]; then
        PROFILE="Ultra Power Saving"
        MODE="power_save"
    elif [ $BAT -le 30 ]; then
        PROFILE="Extreme Power Saving"
        MODE="power_save"
    elif [ $BAT -le 40 ]; then
        PROFILE="High Power Saving"
        MODE="power_save"
    elif [ $BAT -le 50 ]; then
        PROFILE="Balanced Saving"
        MODE="balanced"
    elif [ $BAT -le 60 ]; then
        PROFILE="Light Performance"
        MODE="balanced"
    elif [ $BAT -le 70 ]; then
        PROFILE="Balanced Performance"
        MODE="balanced"
    elif [ $BAT -le 90 ]; then
        PROFILE="High Performance"
        MODE="performance"
    else
        PROFILE="Maximum Performance"
        MODE="performance"
    fi
    
    echo ""
    echo "Setting Profile: $PROFILE"
    echo "Mode: $MODE"
    
    # Apply performance mode (non-root method)
    settings put global low_power $([[ "$MODE" == "power_save" ]] && echo 1 || echo 0)
    settings put global battery_saver_enabled $([[ "$MODE" == "power_save" ]] && echo 1 || echo 0)
}

# CPU/GPU Optimization (non-root)
optimize_cpu_gpu() {
    echo ""
    echo "========================================="
    echo "  CPU/GPU Optimization"
    echo "========================================="
    
    # Set window animation scale
    case $MODE in
        "performance")
            settings put global window_animation_scale 0.5
            settings put global transition_animation_scale 0.5
            settings put global animator_duration_scale 0.5
            ;;
        "balanced")
            settings put global window_animation_scale 1
            settings put global transition_animation_scale 1
            settings put global animator_duration_scale 1
            ;;
        "power_save")
            settings put global window_animation_scale 0
            settings put global transition_animation_scale 0
            settings put global animator_duration_scale 0
            ;;
    esac
    
    # Force GPU rendering
    if [ "$MODE" = "performance" ]; then
        settings put global debug.hwui.renderer skiagl
        setprop debug.hwui.render_dirty_regions false
        setprop debug.egl.hw 1
        setprop debug.sf.hw 1
    fi
    
    echo "CPU/GPU settings applied"
}

# Improved display refresh rate detection
unlock_high_refresh() {
    echo ""
    echo "========================================="
    echo "  Display Refresh Rate"
    echo "========================================="
    
    # More reliable method to get refresh rate
    CURRENT_RATE=$(dumpsys display 2>/dev/null | grep -m1 "mRefreshRate" | sed 's/.*mRefreshRate=\([0-9.]*\).*/\1/')
    
    # Alternative method if first fails
    if [ -z "$CURRENT_RATE" ]; then
        CURRENT_RATE=$(dumpsys SurfaceFlinger 2>/dev/null | grep "refresh-rate" | head -n1 | awk '{print $2}')
    fi
    
    # Fallback to settings if both fail
    if [ -z "$CURRENT_RATE" ]; then
        CURRENT_RATE=$(settings get system peak_refresh_rate 2>/dev/null)
    fi
    
    # Display result
    if [ -n "$CURRENT_RATE" ]; then
        echo "Current: ${CURRENT_RATE}Hz"
    else
        echo "Current: Unable to detect"
    fi
    
    # Try to set peak refresh rate based on mode
    if [ "$MODE" = "performance" ] || [ "$MODE" = "balanced" ]; then
        settings put system peak_refresh_rate 144.0 2>/dev/null
        settings put system min_refresh_rate 60.0 2>/dev/null
        echo "Target: 144Hz peak / 60Hz minimum"
    else
        settings put system peak_refresh_rate 60.0 2>/dev/null
        settings put system min_refresh_rate 60.0 2>/dev/null
        echo "Target: 60Hz (power saving)"
    fi
    
    # Get display size without verbose output
    SIZE=$(wm size 2>/dev/null | grep "Physical size" | cut -d: -f2 | tr -d ' ')
    DENSITY=$(wm density 2>/dev/null | grep "Physical density" | cut -d: -f2 | tr -d ' ')
    
    if [ -n "$SIZE" ]; then
        echo "Display: ${SIZE} @ ${DENSITY}dpi"
    fi
}

# Performance tweaks
apply_performance_tweaks() {
    echo ""
    echo "========================================="
    echo "  Performance Tweaks"
    echo "========================================="
    
    # Disable automatic updates when on performance mode
    if [ "$MODE" = "performance" ]; then
        settings put global ota_disable_automatic_update 1
        settings put global wifi_scan_always_enabled 0
    fi
    
    # Optimize touch responsiveness
    settings put secure tap_gesture 1
    
    # Reduce motion
    if [ "$MODE" = "power_save" ]; then
        settings put global transition_animation_scale 0
    fi
    
    echo "Performance tweaks applied"
}

# Main execution
echo ""
echo "Applying optimizations..."

# Set profile based on battery
set_performance_profile $BATTERY_LEVEL

# Apply optimizations
optimize_cpu_gpu
unlock_high_refresh
apply_performance_tweaks

echo ""
echo "========================================="
echo "  Optimization Complete!"
echo "========================================="
echo ""
echo "Profile: $PROFILE"
echo "Status: Active"
echo ""
echo "Note: Some features require developer"
echo "options enabled. Reboot for full effect."
echo ""
echo "========================================="