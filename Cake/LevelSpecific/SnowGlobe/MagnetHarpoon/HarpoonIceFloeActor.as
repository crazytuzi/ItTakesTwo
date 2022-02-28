class AHarpoonIceFloeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshUnderComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bAutoDisable = true;
	default Disable.bRenderWhileDisabled = true;
	default Disable.bActorIsVisualOnly = true;
	default Disable.AutoDisableRange = 10000.f;

	UPROPERTY()
	FVector StartLoc;

	UPROPERTY()
	float StartDelay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
	}
}