extends Node

func _ready() -> void:
	World.get_world_instance().set_local_player($"../Player")
	
	call_deferred("test")

func test() -> void:
	ModManager.load_mods(["/mnt/Schnelle Ficke/code/Godot/Automatisation Game/mods/Base.pck"])
	
	#print_mods()
	#print_mod_details()
	#test_storage()
	#test_machine()
	#test_conveyorbelt()
	test_world()

func print_mods() -> void:
	print("Mods:\t\t\t", ModManager.get_mods())

func print_mod_details() -> void:
	print("Items:\t\t\t", ItemStore.get_items())
	print("Machines:\t\t", MachineStore.get_machines())
	print("Recipes:\t\t", RecipeBook.get_recipes())
	print("Storages:\t\t", StorageHall.get_storages())
	print("Conveyor Belts:\t", ConveyorBeltWarehouse.get_conveyorbelts())

func test_storage() -> void:
	var container := StorageHall.instantiate("Small Container")
	
	container.add_item("Cube", 2)
	container.add_item("Sphere", 3)
	container.add_item("Cube", 1)
	container.add_item("Cube", 49)
	
	container.remove_item("Cube", 16)
	
	container.add_item("Prism", 1)
	container.remove_item("Prism", 1)
	container.add_item("Prism", 1)
	
	print(container.get_inventory())

func test_machine() -> void:
	var miner := MachineStore.instantiate("Miner")
	var machine := MachineStore.instantiate("Combiner")
	
	miner.assign_recipe("Sphere")
	machine.assign_recipe("Capsule")
	
	print("Miner:\t\t", miner.get_inventory())
	print("Combiner:\t", machine.get_inventory())

func test_conveyorbelt() -> void:
	var conv := ConveyorBeltWarehouse.instantiate("Slow Conveyor Belt")
	
	print("ConveyorBelt:\t", conv.get_items())

func test_world() -> void:
	var machine := MachineStore.instantiate("Miner")
	machine.position = Vector3(0.0, 0.0, 0.0)
	machine.assign_recipe("Cube")
	World.get_world_instance().add_machine(machine)
	
	var belt := ConveyorBeltWarehouse.instantiate("Slow Conveyor Belt")
	belt.position = Vector3(0.0, 0.0, 0.0)
	belt.add_point(Vector3(0.0, 0.0, 0.0))
	belt.add_point(Vector3(6.0, 0.0, 0.0))
	machine.set_output(belt, 0)
	World.get_world_instance().add_conveyorbelt(belt)
	
	var storage := StorageHall.instantiate("Small Container")
	storage.position = Vector3(6.0, 0.0, 0.0)
	belt.set_output(storage)
	World.get_world_instance().add_storage(storage)
	
	#while true:
		#await get_tree().create_timer(0.1).timeout
		#print("Machine:\t\t", machine.get_inventory())
		#print("Conveyor Belt:\t", belt.get_items())
		#print("Storage:\t", storage.get_inventory())
		#print("\n")
