class ASplineBoatTurntable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorTag(n"Turntable");
	}

	void AttachBoatState(AActor OtherActor, bool bIsAttaching)
	{
		if (bIsAttaching)
			AttachToActor(OtherActor, NAME_None, EAttachmentRule::KeepWorld);
		else
			DetachRootComponentFromParent(); 
	}
}