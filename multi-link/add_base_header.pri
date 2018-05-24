#---------------------------------------------------------------------------------
#app_base_header.pri
#应用程序和Library的基础header。
#---------------------------------------------------------------------------------
#################################################################
##definition and configration
##need QSYS
##################################################################in theory, this should not be limited to 4.8.0, no limit is good.
##Qt version
QT += core sql network gui xml
greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

# release open debug output
CONFIG(debug, debug|release) {
} else {
    DEFINES -= QT_NO_DEBUG_OUTPUT
}

#compatible old version QQt (deperated)
greaterThan(QT_MAJOR_VERSION, 4): DEFINES += __QT5__

#defined in qqtcore.h
#lessThan(QT_MAJOR_VERSION, 5):DEFINES += nullptr=0

#mingw要加速编译，make -j20，-j参数是最好的解决办法。

#close win32 no using fopen_s warning
win32:DEFINES += _CRT_SECURE_NO_WARNINGS #fopen fopen_s

#msvc支持设置
msvc {
    MSVC_CCFLAGS =
    #this three pragma cause mingw errors
    msvc:MSVC_CCFLAGS += /wd"4819" /wd"4244" /wd"4100"

    #UTF8编码
    DEFINES += __MSVC_UTF8_SUPPORT__
    msvc:MSVC_CCFLAGS += /execution-charset:utf-8
    msvc:MSVC_CCFLAGS += /source-charset:utf-8
    #msvc:MSVC_CCFLAGS += /utf-8 #这一个是快捷方式，顶上边两个。

    #指定/mp编译选项，编译器将使用并行编译，同时起多个编译进程并行编译不同的cpp
    msvc:MSVC_CCFLAGS += /MP
    #指出：这个FLAG只能用于MSVC

    msvc:QMAKE_CFLAGS += $${MSVC_CCFLAGS}
    msvc:QMAKE_CXXFLAGS += $${MSVC_CCFLAGS}

    #指定stable.h这个头文件作为编译预处理文件，MFC里这个文件一般叫stdafx.h 然后在 stable.h里 包含你所用到的所有 Qt 头文件
    #在.pro 文件中加入一行, 加在这里，加速编译。
    #msvc:PRECOMPILED_HEADER = $${PWD}/lib-qt.h
    #指出：precompiler header只能用于MSVC
    #这个功能可用，可是编译问题比较多，不方便，所以默认不开开。
}

#CONFIG += debug_and_release
#CONFIG += build_all
#if some bug occured, maybe this help me, close some warning
CCFLAG =
!win32:CCFLAGS = -Wno-unused-parameter -Wno-reorder -Wno-c++11-extensions -Wno-c++11-long-long -Wno-comment
QMAKE_CFLAGS +=  $${CCFLAGS}
QMAKE_CXXFLAGS +=  $${CCFLAGS}

lessThan(QT_VERSION, 4.8.0) {
    message(A. ensure your compiler support c++11 feature)
    message(B. suggest Qt version >= 4.8.0)
    #error(  error occured!)
}

contains(TEMPLATE, lib) {
    #create sdk need
    CONFIG += create_prl
}

#macOS下必须开开bundle
contains(QSYS_PRIVATE, macOS){
    contains(TEMPLATE, app) {
        CONFIG += app_bundle
    } else: contains(TEMPLATE, lib) {
        #仅仅用这个 这个是lib用的pri
        CONFIG += lib_bundle
    }
}


#################################################################
##version
#################################################################
#user can use app_version.pri to modify app version once, once is all. DEFINES += APP_VERSION=0.0.0 is very good.
#unix:VERSION = $${QQT_VERSION}
#bug?:open this macro, TARGET will suffixed with major version.
#win32:VERSION = $${QQT_VERSION4}
QMAKE_TARGET_FILE = "$${TARGET}"
QMAKE_TARGET_PRODUCT = "$${TARGET}"
QMAKE_TARGET_COMPANY = "www.$${TARGET}.com"
QMAKE_TARGET_DESCRIPTION = "$${TARGET} Foundation Class"
QMAKE_TARGET_COPYRIGHT = "Copyright 2017-2022 $${TARGET} Co., Ltd. All rights reserved"

win32 {
    #common to use upload, this can be ignored.
    #open this can support cmake config.h.in
    #configure_file(qqtversion.h.in, qqtversion.h) control version via cmake.
    #qmake version config and cmake version config is conflicted
    #RC_FILE += qqt.rc
    #RC_ICONS=
    RC_LANG=0x0004
    RC_CODEPAGE=
}

#################################################################
##build lib or link lib
#################################################################
##different target:
##-----------------------------------------------
##win platform:
##build lib dll + LIB_LIBRARY
##build lib lib + LIB_STATIC_LIBRARY
##link lib lib + LIB_STATIC_LIBRARY
##link lib dll + ~~
##- - - - - - - - - - - - - - - - - - - - -
##*nix platform:
##build and link lib dll or lib + ~~
##-----------------------------------------------
#link Lib static library in some occation on windows
#when link Lib    static library, if no this macro, headers can't be linked on windows.
#在这里添加了LIB_STATIC_LIBRARY 用户可以使用 还有LIB_LIBRARY
contains(QSYS_PRIVATE, Win32|Win64 || iOS|iOSSimulator) {
    #Qt is static by mingw32 building
    mingw|ios{
        #on my computer, Qt library are all static library?
        DEFINES += LIB_STATIC_LIBRARY
        message(Build $${TARGET} LIB_STATIC_LIBRARY is defined. build and link)
    }

    #link and build all need this macro
    contains(DEFINES, LIB_STATIC_LIBRARY) {
    }
}

################################################################
##build cache (此处为中间目标目录，对用户并不重要)
##此处加以干涉，使目录清晰。
##此处关于DESTDIR的设置，导致用户必须把这个文件的包含，提前到最前边的位置，才能进行App里的目录操作。
##删除干涉?
##用户注意：(done in app_base_manager), 首先include(app_link_lib_library.pri)，然后做app的工作，和include其他pri，包括LibLib提供的其他pri，保证这个顺序就不会出错了。
##对编译目标目录进行干涉管理，显得更加细腻。
##用户注意：这里相当于给编译中间目录加了一个自动校准，属于校正范畴。
################################################################
isEmpty(OBJECTS_DIR):OBJECTS_DIR = obj
isEmpty(MOC_DIR):MOC_DIR = obj/moc.cpp
isEmpty(UI_DIR):UI_DIR = obj/ui.h
isEmpty(RCC_DIR):RCC_DIR = qrc
#这样做保持了App工程和LibLib工程中间目录的一致性，但是并不必要。
isEmpty(DESTDIR):DESTDIR = bin

################################################################
##Lib Functions Macro
################################################################
#You need switch these more macro according to your needs when you build this library
#You can tailor Lib  with these macro.
#Default: macroes is configed, some open, some close, compatibled to special accotation.
##App希望裁剪LibLib，开关这个文件里的组件宏，用户有必要读懂这个头文件。up to so.

##################C++11 Module###############################
#if you use C++11, open this annotation. suggest: ignore
#DEFINES += __CPP11__
contains (DEFINES, __CPP11__) {
    #macOS gcc Qt4.8.7
    #qobject.h fatal error: 'initializer_list' file not found,
    #Qt4.8.7 can't support c++11 features
    #QMAKE_CXXFLAGS += "-std=c++11"
    #QMAKE_CXXFLAGS += "-std=c++0x"

    #below: gcc version > 4.6.3
    #Open this Config, Why in Qt4 works? see qmake config auto ignored this feature.
    #In Qt5? don't need open this config, qmake auto add c++11 support on linux plat.
    #on windows mingw32? need test
    #CONFIG += c++11

    #compile period
    #LibLib need c++11 support. Please ensure your compiler version.
    #LibLib used override identifier
    #lambda also need c++11
}

#################################################################
##library
##################################################################
equals (QKIT_PRIVATE, iOSSimulator):{
    #error need
    #QMAKE_CXXFLAGS +=-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
}

win32 {
    LIBS += -luser32
    LIBS += -lopengl32 -lglu32
}else: unix {
    equals(QSYS_PRIVATE, macOS) {
        #min macosx target
        QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9
        #deperated
        #QMAKE_MAC_SDK=macosx10.12
        #MACOSXSDK = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$${QMAKE_MACOSX_DEPLOYMENT_TARGET}.sdk
        #QMAKE_LIBDIR = $${MACOSXSDK}
        #LIBS += -F$${MACOSXSDK}/System/Library/Frameworks
        #LIBS += -L$${MACOSXSDK}/usr/lib
        LIBS += -framework DiskArbitration -framework Cocoa -framework IOKit
    }else:contains(QSYS_PRIVATE, iOS|iOSSimulator){
        QMAKE_LFLAGS += -ObjC -lsqlite3 -lz
        QMAKE_IOS_DEPLOYMENT_TARGET = 8
    }
}
