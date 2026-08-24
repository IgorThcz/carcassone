@tool
extends EditorScript

const OUTPUT_DIR := "res://Resources/UVShiftedMeshs/"
const MATERIAL_PATH := "res://Resources/Materials/floor_atlas.tres"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	var uv_slice: float = 1.0 / 8.0
	var material := load(MATERIAL_PATH) as StandardMaterial3D

	if material == null:
		push_error("Não foi possível carregar o material: " + MATERIAL_PATH)
		return

	for i in range(6):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var uv_offset := Vector2(uv_slice * i, 0.0)

		# --------------------------------------------------
		# Vértice 0: Top-Left
		# --------------------------------------------------
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 0.0) + uv_offset)
		st.add_vertex(Vector3(-3.2, 0.0, -3.2))

		# --------------------------------------------------
		# Vértice 1: Top-Right
		# --------------------------------------------------
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(uv_slice, 0.0) + uv_offset)
		st.add_vertex(Vector3(3.2, 0.0, -3.2))

		# --------------------------------------------------
		# Vértice 2: Bottom-Right
		# --------------------------------------------------
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(uv_slice, 1.0) + uv_offset)
		st.add_vertex(Vector3(3.2, 0.0, 3.2))

		# --------------------------------------------------
		# Vértice 3: Bottom-Left
		# --------------------------------------------------
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.0, 1.0) + uv_offset)
		st.add_vertex(Vector3(-3.2, 0.0, 3.2))

		# --------------------------------------------------
		# Triângulo 1
		# Winding CCW visto de cima
		# --------------------------------------------------
		st.add_index(0)
		st.add_index(2)
		st.add_index(3)

		# --------------------------------------------------
		# Triângulo 2
		# --------------------------------------------------
		st.add_index(0)
		st.add_index(1)
		st.add_index(2)

		# --------------------------------------------------
		# Cria a ArrayMesh
		# --------------------------------------------------
		var new_mesh: ArrayMesh = st.commit()

		if new_mesh == null:
			push_error("Falha ao criar mesh " + str(i + 1))
			continue

		# --------------------------------------------------
		# Aplica o material
		# --------------------------------------------------
		new_mesh.surface_set_material(0, material)

		# --------------------------------------------------
		# Salva
		# --------------------------------------------------
		var save_path := OUTPUT_DIR + "plane_uv_region_" + str(i + 1) + ".tres"

		var error := ResourceSaver.save(new_mesh, save_path)

		if error != OK:
			push_error(
				"Erro ao salvar Mesh %d: %s"
				% [i + 1, str(error)]
			)
		else:
			print(
				"Mesh %d criada | UV X: %.3f -> %.3f"
				% [
					i + 1,
					uv_slice * i,
					uv_slice * (i + 1)
				]
			)

	EditorInterface.get_resource_filesystem().scan()

	print("--- 6 MESHES GERADAS E CACHE ATUALIZADO ---")
