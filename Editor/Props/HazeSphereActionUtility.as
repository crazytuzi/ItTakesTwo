import Cake.Environment.HazeSphere;

class UHazeSphereActionUtility : UActorActionUtility
{
	UFUNCTION(BlueprintOverride)
	UClass GetSupportedClass() const
	{
		return AHazeSphere::StaticClass();
	}

	UFUNCTION(CallInEditor, Category = "Tech Art")
	void SetStatic()
	{
		TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
		for (AActor Actor : SelectedActors)
		{
			Actor.GetRootComponent().SetMobility(EComponentMobility::Static);
		}
	}
}