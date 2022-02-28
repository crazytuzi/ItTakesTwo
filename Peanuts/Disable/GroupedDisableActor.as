
// Used for visualizer
UCLASS(Meta = (HideCategories = "LOD Activation Tags AssetUserData Debug"))
class UGroupedDisableComponent : UHazeDisableComponent
{
}

UCLASS(Meta = (HideCategories = "Tags AssetUserData Collision Cooking Transform Activation Rendering Replication Input Actor LOD Debug"))
class AGroupedDisableActor : AHazeActor
{
	default AddActorTag(n"GroupedDisable");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGroupedDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;
};