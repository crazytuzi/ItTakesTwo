UCLASS(Abstract)
class AGardenFly : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent FlyBody;
	default FlyBody.SetCollisionProfileName(n"IgnorePlayerCharacter");

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftWingRoot;

	UPROPERTY(DefaultComponent, Attach = LeftWingRoot)
	UStaticMeshComponent LeftWing;
	default LeftWing.SetCollisionProfileName(n"NoCollision");
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightWingRoot;

	UPROPERTY(DefaultComponent, Attach = RightWingRoot)
	UStaticMeshComponent RightWing;
	default RightWing.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike WingsTimeLike;

	// The Frog that is attempting to eat this fly
	AHazeActor FrogEater = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WingsTimeLike.BindUpdate(this, n"UpdateWings");
		WingsTimeLike.SetPlayRate(10.f);
		WingsTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateWings(float CurValue)
	{
		FRotator LeftRot = FMath::LerpShortestPath(FRotator(0.f, 0.f, 45.f), FRotator(0.f, 0.f, -45.f), CurValue);
		FRotator RightRot = FMath::LerpShortestPath(FRotator(0.f, 0.f, -45.f), FRotator(0.f, 0.f, 45.f), CurValue);

		LeftWingRoot.SetRelativeRotation(LeftRot);
		RightWingRoot.SetRelativeRotation(RightRot);
	}
}