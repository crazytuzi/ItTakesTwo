class UCannonSpring : UActorComponent
{

	UPROPERTY()
	FHazeTimeLike TimeLike;

	default TimeLike.Duration = 1;
	default TimeLike.SyncTag = n"Oscillation";

	int TightensMade = 0;
	float ZScale = 0;

	UPROPERTY()
	AHazeActor ActorToFollow;

	UPROPERTY()
	USceneComponent PointActorShouldFollow;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeLike.BindUpdate(this, n"UpdateTimeLike");
		
		TArray<USceneComponent> SceneComponents;
		Owner.GetComponentsByClass(SceneComponents);

		for (auto component : SceneComponents)
		{
			if (component.Name == "Scene")
			{
				PointActorShouldFollow = component;
				break;
			}
		}
	}

	UFUNCTION()
	void TightenSpring()
	{
		TightensMade++;
		ZScale = Owner.GetActorScale3D().Z;
		TimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		FVector Scale = Owner.GetActorScale3D();
		Scale.Z = FMath::Lerp(ZScale, 1 - (TightensMade * 0.33f), TimeLike.Value);
		Owner.SetActorScale3D(Scale);
		ActorToFollow.SetActorLocation(PointActorShouldFollow.WorldLocation);
	}
}