class ACourtyardCakeCharacter : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UCapsuleComponent Capsule;
	default Capsule.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Capsule.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 4000.f;

	UPROPERTY()
	FHazePlayRndSequenceData CakeDestroyedIdles;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Capsule.SetRelativeLocation(FVector(0.f, 0.f, Capsule.CapsuleHalfHeight));
	}

	void CakeDestroyed()
	{
		Mesh.PlayIdleOverrideAnimations(CakeDestroyedIdles);
	}
}