@tool
class_name VCSEditorExportPlatform
extends ToolEditorExportPlatform

## SourceEditorExportPlatform
## 
## A simple export plugin for godot that connects the editor VCS interface
## to the export menu. Requires the NovaTools plugin as a dependency.

func _get_name():
	return "VCS"

func _get_logo():
	var size = Vector2i.ONE * floori(32 * EditorInterface.get_editor_scale())
	return NovaTools.get_editor_icon_named("VcsBranches", size)

func _get_preset_features(preset:EditorExportPreset) -> PackedStringArray:
	var feat := PackedStringArray()
	if preset.get_or_env("stage", ""):
		feat.append("stage")
	
	if preset.get_or_env("commit", ""):
		feat.append("commit")
	
	if preset.get_or_env("push", ""):
		feat.append("push")
	
	return feat

func _get_export_option_visibility(preset: EditorExportPreset, option: String) -> bool:
	match (option):
		"commit_message":
			return preset.get_or_env("commit", "")
		"remote", "force_push":
			return preset.get_or_env("push", "")
		_:
			return true

func _get_export_options():
	var possible_remotes:Array = NovaTools.try_callv_vcs_method("get_remotes", [], [])
	return [
		{
			"name": "branch",
			"type": TYPE_STRING,
			"default_value": NovaTools.try_callv_vcs_method("get_current_branch_name", [], "")
		},
		{
			"name": "only_if_changed",
			"type": TYPE_BOOL,
			"default_value": true
		},
		
		{
			"name": "stage",
			"type": TYPE_BOOL,
			"default_value": false
		},
		
		{
			"name": "commit",
			"type": TYPE_BOOL,
			"default_value": false,
			"update_visibility": true
		},
		{
			"name": "commit_message",
			"type": TYPE_STRING,
			"default_value": ""
		},
		
		{
			"name": "push",
			"type": TYPE_BOOL,
			"default_value": false,
			"update_visibility": true
		},
		{
			"name": "remote",
			"type": TYPE_STRING,
			"default_value": possible_remotes[0] if possible_remotes.size() > 0 else ""
		},
		{
			"name": "force_push",
			"type": TYPE_BOOL,
			"default_value": false
		},
	] + super._get_export_options()

func _has_valid_project_configuration(preset: EditorExportPreset):
	return (NovaTools.vcs_active() and
			(not preset.get_or_env("push", "") or
			 preset.get_or_env("remote", "") in NovaTools.callv_vcs_method("get_remotes")
			)
		   )

func _export_hook(preset: EditorExportPreset, path: String):
	if preset.get_or_env("only_if_changed", "") and not NovaTools.vcs_is_something_changed():
		return OK
	
	var original_branch := NovaTools.callv_vcs_method("get_current_branch_name")
	var branch = preset.get_or_env("branch", "")
	if branch != original_branch:
		if branch not in NovaTools.callv_vcs_method("get_branch_lists"):
			NovaTools.callv_vcs_method("create_branch", [branch])
		NovaTools.callv_vcs_method("checkout_branch", [branch])
	
	if preset.get_or_env("stage", ""):
		for file in NovaTools.get_children_files_recursive(ProjectSettings.globalize_path(path)):
			NovaTools.callv_vcs_method("stage_file", [file])
	
	if preset.get_or_env("commit", ""):
		NovaTools.callv_vcs_method("commit", [preset.get_or_env("commit_message", "")])
	
	if preset.get_or_env("push", ""):
		NovaTools.callv_vcs_method("push",
								   [preset.get_or_env("remote", ""),
									preset.get_or_env("force_push", "")
								   ]
								  )

	if branch != original_branch:
		NovaTools.callv_vcs_method("checkout_branch", [original_branch])

	return OK
