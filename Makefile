SRC_DIR = src
INC_DIR = include
BUILD_DIR = build

AS = rgbasm
ASFLAGS = -i $(INC_DIR)/ -i $(BUILD_DIR)/
LD = rgblink

ASM_FILES = $(wildcard $(SRC_DIR)/*.asm)
OBJ_FILES = $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(ASM_FILES:.asm=.o))
PNG_FILES = $(wildcard $(SRC_DIR)/*.png)
2BPP_FILES = $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(PNG_FILES:.png=.2bpp))
BIN_FILE = cart.gb

$(BIN_FILE): $(OBJ_FILES)
	$(LD) -o $(BIN_FILE) $(OBJ_FILES)
	rgbfix -v -p 0 $(BIN_FILE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.2bpp: $(SRC_DIR)/%.png $(BUILD_DIR)
	rgbgfx -o $@ $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm $(2BPP_FILES) $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

run: $(BIN_FILE)
	open -a SameBoy $(BIN_FILE)

clean:
	rm -rf $(BUILD_DIR) $(BIN_FILE)
