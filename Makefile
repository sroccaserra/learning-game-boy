SRC_DIR = src
INC_DIR = include
BUILD_DIR = build

AS = rgbasm
ASFLAGS = -i $(INC_DIR)/
LD = rgblink

ASM_FILES = $(wildcard $(SRC_DIR)/*.asm)
OBJ_FILES = $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(ASM_FILES:.asm=.o))
BIN_FILE = cart.gb

$(BIN_FILE): $(OBJ_FILES)
	$(LD) -o $(BIN_FILE) $(OBJ_FILES)
	rgbfix -v -p 0 $(BIN_FILE)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

run: $(BIN_FILE)
	open -a SameBoy $(BIN_FILE)

clean:
	rm -rf $(BUILD_DIR) $(BIN_FILE)
