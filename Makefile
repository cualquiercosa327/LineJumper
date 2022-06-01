DEVKITPRO := /opt/devkitpro
DEVKITARM := /opt/devkitpro/devkitARM

PATH := $(DEVKITARM)/bin:$(PATH)

TITLE		:= LineJumper

#  Project settings

NAME		:= $(TITLE)
SOURCE_DIR 	:= source
DATA_DIR    := assets/build # ????
SPECS       := -specs=gba.specs

# Compilation settings

CROSS	?= arm-none-eabi-
CC	:= $(CROSS)gcc
LD	:= $(CROSS)gcc
OBJCOPY	:= $(CROSS)objcopy
LDC     := ldc2

ARCH	:= -mthumb-interwork -mthumb

# Include libtonc and other devkit pro things
# For now I won't be using this
# INCFLAGS := --I$(DEVKITPRO)/libtonc/include -I$(DEVKITPRO)/libgba/include -I$(SOURCE_DIR) -I$(DATA_DIR)
# LIBFLAGS := -L$(DEVKITPRO)/libtonc/lib -ltonc -L$(DEVKITPRO)/libgba/lib -lmm

CFLAGS	:= $(ARCH) -Wall -Werror -Wno-error=unused-variable -fno-strict-aliasing -mcpu=arm7tdmi -mtune=arm7tdmi $(INCFLAGS) $(LIBFLAGS)

LDFLAGS	:= $(ARCH) $(SPECS) $(LIBFLAGS) -Wl,-Map,$(TITLE).map

DFLAGS  := -betterC --defaultlib=no -mtriple=arm-none-eabi -mcpu=arm7tdmi \
		   -mattr=+strict-align,+loop-align\
		   -I$(SOURCE_DIR) \
		   --d-version=DevkitARM --d-version=CRuntime_Newlib_GBA --d-version=_GBA \
		   -function-sections

# Don't inclue libd, I won't be using it... probably...
# DSTDLIB := libd
# DFLAGS += -I$(DSTDLIB)

ifeq ($(DEBUG),1)
	CFLAGS += -g -DDEBUG
	DFLAGS += -g --d-version=DEBUG
else
	# non-debug
	CFLAGS += -O2 -fomit-frame-pointer -ffast-math
	DFLAGS += -O2 -frame-pointer=none -ffast-math
endif

.PHONY : build clean

# Find and predetermine all relevant source files

APP_MAIN_SOURCE   := $(shell find $(SOURCE_DIR) -name '*main.c')
APP_MAIN_OBJECT   := $(APP_MAIN_SOURCE:%.c=%.o)
APP_SOURCES_C     := $(shell find $(SOURCE_DIR) -name '*.c' ! -name "*main.c"  ! -name "*.test.c")
APP_SOURCES_S     := $(shell find $(SOURCE_DIR) -name '*.s')
APP_OBJECTS_C     := $(APP_SOURCES_C:%.c=%.o)
APP_OBJECTS_S     := $(APP_SOURCES_S:%.s=%.o)
APP_SOURCES_D     := $(shell find $(DSTDLIB) $(SOURCE_DIR) -name '*.d')
APP_OBJECTS_D     := $(APP_SOURCES_D:%.d=%.o)
APP_OBJECTS		  := $(APP_OBJECTS_C) $(APP_OBJECTS_S) $(APP_OBJECTS_D)

# Build commands and dependencies

.PHONY: build

build: $(NAME).gba

no-content: $(NAME)-code.gba

# GBA ROM Build

$(NAME).gba : $(NAME)-code.gba
	cat $^ > $(NAME).gba

$(NAME)-code.gba : $(NAME).elf
	$(OBJCOPY) -v -O binary $< $@
	-@gbafix $@ -t$(NAME)
	padbin 256 $@

$(NAME).elf : $(APP_OBJECTS) $(APP_MAIN_OBJECT)
	$(LD) $^ $(LDFLAGS) -o $@

$(APP_OBJECTS_C) : %.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(APP_OBJECTS_S) : %.o : %.s
	$(CC) $(CFLAGS) -c $< -o $@

$(APP_OBJECTS_D) : %.o : %.d
	$(LDC) $(DFLAGS) -c -of=$@ $<

$(APP_MAIN_OBJECT) : $(APP_MAIN_SOURCE)
	$(CC) $(CFLAGS) -c $< -o $@

$(NAME).gbfs:
	gbfs $@ $(shell find $(DATA_DIR) -name '*.bin')

clean:
	@rm -fv *.gba
	@rm -fv *.elf
	@rm -fv *.sav
	@rm -fv *.gbfs
	@rm -fv *.map
	@rm -rf $(APP_OBJECTS)
	@rm -rf $(APP_MAIN_OBJECT)
