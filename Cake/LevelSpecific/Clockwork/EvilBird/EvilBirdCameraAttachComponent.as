class UEvilBirdCameraAttachComponent : USceneComponent
{
	UHazeCameraParentComponent FocusTracker;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USkeletalMeshComponent Mesh = USkeletalMeshComponent::Get(Owner);
		AttachToComponent(Mesh, n"Hips");
		

		TArray<UActorComponent> Comps = Owner.GetComponentsByTag(UHazeCameraParentComponent::StaticClass(), n"FocusTracker");
		if (Comps.Num() > 0)
		{
			FocusTracker = Cast<UHazeCameraParentComponent>(Comps[0]);
			if (FocusTracker != nullptr)
				FocusTracker.DetachFromParent();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetRelativeRotation(FRotator(-15, 0, 0));
		FVector RelLoc = FVector(-2000, 0, 1300);
		SetRelativeLocation(RelLoc);

		if (FocusTracker != nullptr)
			FocusTracker.SetWorldLocation(Owner.ActorLocation);
	}
}