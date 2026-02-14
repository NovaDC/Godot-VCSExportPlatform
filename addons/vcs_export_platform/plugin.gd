@tool
extends EditorPlugin

const PLUGIN_NAME := "VCS Export Platform"

const PLUGIN_NAME_INTERNAL := "vcs_export_platform"

const ENSURE_SCRIPT_DOCS:Array[Script] = [
    preload("./vcs_export_platform.gd")
]

var _export_platform_ref:VCSEditorExportPlatform = null

# Every once ands a while the script docs simply refuse to update properly.
# This nudges the docs into a ensuring that the important scripts added by
# this addon are actually loaded.
func _ensure_script_docs():
    var edit := get_editor_interface().get_script_editor()
    for scr in ENSURE_SCRIPT_DOCS:
        edit.update_docs_from_script(scr)

func _get_plugin_name():
    return PLUGIN_NAME

func _get_plugin_icon():
    return NovaTools.get_editor_icon_named(VCSEditorExportPlatform.EDITOR_ICON_NAME,
                                            Vector2i.ONE * 16
                                            )

func _enter_tree():
    _ensure_script_docs()
    if EditorInterface.is_plugin_enabled(PLUGIN_NAME_INTERNAL):
        _try_init_platform()

func _enable_plugin():
    _ensure_script_docs()
    _try_init_platform()

func _disable_plugin():
    _try_deinit_platform()

func _exit_tree():
    _try_deinit_platform()

func _try_init_platform():
    if _export_platform_ref == null:
        _export_platform_ref = VCSEditorExportPlatform.new()
        add_export_platform(_export_platform_ref)

func _try_deinit_platform():
    if _export_platform_ref != null:
        remove_export_platform(_export_platform_ref)
        _export_platform_ref = null
