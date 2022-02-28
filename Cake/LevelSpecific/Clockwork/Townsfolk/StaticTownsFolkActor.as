class AStaticTownsFolkActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;
	default SkelMeshComp.bComponentUseFixedSkelBounds = true;
	default SkelMeshComp.bEnableUpdateRateOptimizations = true;
	default SkelMeshComp.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCapsuleComponent PlayerCollision;
	default PlayerCollision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default PlayerCollision.bGenerateOverlapEvents = false;
	default PlayerCollision.RemoveTag(n"Walkable");

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Platform.SetCullDistance(Editor::GetDefaultCullingDistance(Platform) * CullDistanceMultiplier);
		SkelMeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(SkelMeshComp) * CullDistanceMultiplier);
	}
}