NAME		:=lib_math.a

CC			:=cc
WFLAGS		:=-Wall -Wextra -Werror -Wpedantic -Wunreachable-code -Wshadow -Wnull-dereference -Wfloat-equal -Wcast-align -Wformat=2 -Wundef
DEFS		:=
DFLAGS		:=-D DEBUG -g
SANFLAGS	:=-fsanitize=address,undefined,alignment -fno-omit-frame-pointer

UNAME_S		:=$(shell uname -s)
UNAME_M		:=$(shell uname -m)
COMPILER_ID	:= $(shell $(CC) --version 2>/dev/null)
ifneq (,$(findstring clang,$(COMPILER_ID)))
	AR		:= llvm-ar
else ifneq (,$(findstring gcc,$(COMPILER_ID))$(findstring GCC,$(COMPILER_ID)))
	AR		:= gcc-ar
else
	AR		:= ar
endif
ifeq ($(UNAME_S),Darwin)
	AR		:= ar
endif

OPTS		:=-O3 -ffast-math -funroll-loops -flto -DNDEBUG
ifeq ($(UNAME_S),Darwin)
	ifeq ($(UNAME_M),arm64)
		OPTS	+=-mcpu=native
	else
		OPTS	+=-march=native
	endif
else
	OPTS		+=-march=haswell -fno-plt
endif

CFLAGS		:=$(WFLAGS) $(DEFS) $(OPTS)
ifeq ($(MAKELEVEL),0)
	MAKEFLAGS	+= --no-print-directory -j$(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
endif

DIR_NAME	:= $(notdir $(CURDIR))
DIR_INC		:=inc/
DIR_SRC		:=src/
DIR_OBJ		:=obj/
DIR_DEP		:=dep/

INCS		:=$(addprefix -I, $(DIR_INC))
ifeq ($(UNAME_S),Darwin)
	INCS	+=-I"/opt/homebrew/include" -I"/usr/local/include" -I"/opt/local/include"
endif

SRCS		:=$(addprefix $(DIR_SRC), \
				math.c mat4.c mat4_transforms.c \
				vec4.c vec3.c vec3_2.c mat4_utils.c mat4_inverse.c \
				vec2.c vec4_2.c vec2i.c vec2i_2.c math_2.c math_3.c \
				vec3_3.c color.c v4sf.c v4si.c coords.c quaternion.c \
				mat4_transforms_2.c random.c vec3_4.c vec3_5.c vec3_6.c \
				fast_math.c quaternion_2.c mapping.c)
OBJS		:=$(patsubst $(DIR_SRC)%.c, $(DIR_OBJ)%.o, $(SRCS))
DEPS		:=$(patsubst $(DIR_OBJ)%.o, $(DIR_DEP)%.d, $(OBJS))

BLUE		:=\033[1;34m
YELLOW		:=\033[1;33m
GREEN		:=\033[1;32m
RED			:=\033[1;31m
COLOR		:=\033[0m

all: $(NAME)

compdb:
	@if command -v bear >/dev/null 2>&1; then \
		bear --append -- $(MAKE) all; \
	elif command -v compiledb >/dev/null 2>&1; then \
		compiledb $(MAKE) all; \
	else \
		$(MAKE) all; \
	fi

$(NAME): $(OBJS)
	@$(AR) -rcs $(NAME) $(OBJS)
	@$(call output)

$(DIR_OBJ)%.o: $(DIR_SRC)%.c
	@$(call compile_objs)

clean:
	@$(call rm_dir,$(DIR_OBJ))
	@$(call rm_dir,.cache/)

fclean: clean
	@$(call rm_dir,$(DIR_DEP))
	@$(call rm_file,$(NAME))
	@$(call rm_file,compile_commands.json)

re:
	@$(MAKE) fclean 2> /dev/null
	@$(MAKE) all

debug:
	@$(MAKE) fclean
	@$(MAKE) all OPTS="$(DEBUG)" BUILD_TYPE="DEBUG"

debugdb:
	@$(MAKE) fclean
	@$(MAKE) compdb OPTS="$(DEBUG)" BUILD_TYPE="DEBUG"

.PHONY: all clean fclean re debug compdb debugdb
.SECONDARY: $(OBJS) $(DEPS)

-include $(DEPS)

define compile_objs
	@mkdir -p $(dir $@) $(patsubst $(DIR_OBJ)%, $(DIR_DEP)%, $(dir $@))
	@$(CC) $(CFLAGS) -c $< -o $@ -MMD -MP -MF $(patsubst $(DIR_OBJ)%.o, $(DIR_DEP)%.d, $@) $(INCS)
	@echo "$(GREEN) [+]$(COLOR) compiling $@"
endef

define rm_dir
	@if [ -d "$(1)" ]; then \
		rm -rf $(1); \
		echo "$(RED) [-]$(COLOR) removed $(DIR_NAME)/$(1)"; \
	fi
endef

define rm_file
	@if [ -e "$(1)" ]; then \
		rm -f $(1); \
		echo "$(RED) [-]$(COLOR) removed $(DIR_NAME)/$(1)"; \
	fi
endef

define output
	echo "$(YELLOW) [✔] $(NAME) created$(COLOR)"
	if [ "$(BUILD_TYPE)" = "DEBUG" ]; then \
		echo "$(YELLOW) [DEBUG]$(COLOR)"; \
	fi;
endef
