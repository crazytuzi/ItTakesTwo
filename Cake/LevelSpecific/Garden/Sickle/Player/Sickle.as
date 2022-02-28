
UCLASS(Abstract, HideCategories = "Tick Replication Actor Input Debug LOD Cooking Collision Rendering Mobile Replication")
class ASickle : AHazeActor
{
    default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(RootComponent, DefaultComponent)
	UStaticMeshComponent SickleMesh;
	default SickleMesh.AddTag(ComponentTags::HideOnCameraOverlap);
	default SickleMesh.bReceiveWorldShadows = false;

	UPROPERTY(Category = "Sickle")
	FTransform AttachTransform(FRotator(10.f, 0.f, 90.f), FVector(0.f, 0.f, 5.f));

	UPROPERTY(DefaultComponent, Category = "Sickle")
	UNiagaraComponent TrailEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetTrailEnabled(false);	
	}

	void SetTrailEnabled(bool bStatus)
	{
		if(TrailEffect != nullptr)
			TrailEffect.SetHiddenInGame(!bStatus);
	}

	void OnAttachedToPlayer()
	{
		SickleMesh.HazeSetShadowPriority(EShadowPriority::Player);
	}

	void OnAttachedToWaterHose()
	{
		SickleMesh.HazeSetShadowPriority(EShadowPriority::GameplayElement);
	}
}
