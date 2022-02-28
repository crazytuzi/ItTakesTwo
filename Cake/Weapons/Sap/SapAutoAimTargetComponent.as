import Peanuts.Aiming.AutoAimTarget;

enum ESapAutoAimHighlightMode
{
	None,
	SpecificMeshes,
	ParentMesh,
	ParentMeshRecursive,
	AllMeshes
}

class USapAutoAimTargetComponent : UAutoAimTargetComponent
{
	UPROPERTY(Category = "SapAutoAim")
	ESapAutoAimHighlightMode HighlightMode = ESapAutoAimHighlightMode::AllMeshes;

	// Only relevant if the "SpecificMeshes" mode is specified
	UPROPERTY(Category = "SapAutoAim")
	TArray<UMeshComponent> SpecificMeshesToHighlight;

	UPROPERTY(Category = "SapAutoAim", meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float SapLobHeightScale = 1.f;
}