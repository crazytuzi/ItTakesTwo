import Peanuts.Disable.AutoDisableRotatingMovement;

class UHazeRotatingPropActionUtility : UActorActionUtility
{
    UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
        return AStaticMeshActor::StaticClass();
    }

    /* Add a AutoDisableRotatingMovementComponent to all static meshes with rotating movement components.  */
    UFUNCTION(CallInEditor, Category = "Prop Actions")
    void AddAutoDisableRotatingMovementComponent()
    {
        TArray<AActor> SelectedActors = EditorUtility::GetSelectionSet();
        for (AActor Actor : SelectedActors)
        {
			AStaticMeshActor MeshActor = Cast<AStaticMeshActor>(Actor);
			if (MeshActor == nullptr)
				continue;

			auto RotatingComp = URotatingMovementComponent::Get(Actor);
			if (RotatingComp == nullptr)
				continue;

			auto DisableComp = UAutoDisableRotatingMovementComponent::Get(Actor);
			if (DisableComp != nullptr)
				continue;

			Editor::AddInstanceComponentInEditor(Actor, UAutoDisableRotatingMovementComponent::StaticClass(), n"RotationDisable");
		}
    }
};