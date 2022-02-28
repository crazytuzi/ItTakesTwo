UCLASS(Abstract)
class AVacuumFollowLamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LampRoot;

	UPROPERTY(DefaultComponent, Attach = LampRoot)
	UStaticMeshComponent LampMesh;

	UPROPERTY(DefaultComponent, Attach = LampRoot)
	USpotLightComponent SpotLightComp;

	float MaxFollowDistance = 5500.f;

	int CurrentLightIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer;

		float DistanceToMay = GetDistanceTo(Game::GetMay());
		float DistanceToCody = GetDistanceTo(Game::GetCody());

		if (DistanceToMay >= MaxFollowDistance && DistanceToMay >= MaxFollowDistance)
			return;

		if (DistanceToMay <= DistanceToCody)
			ClosestPlayer = Game::GetMay();
		else
			ClosestPlayer = Game::GetCody();

		FVector DirToPlayer = ClosestPlayer.ActorLocation - ActorLocation;
		DirToPlayer = DirToPlayer.GetSafeNormal();

		FRotator CurRot = FMath::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, 5.f);
		SetActorRotation(CurRot);
	}

	UFUNCTION()
	void ChangeLightColor()
	{
		CurrentLightIndex++;
		if (CurrentLightIndex == 3)
			CurrentLightIndex = 0;

		if (CurrentLightIndex == 0)
			SpotLightComp.SetTemperature(3800.f);
		else if (CurrentLightIndex == 1)
			SpotLightComp.SetTemperature(12000.f);
		else
			SpotLightComp.SetTemperature(1000.f);

		BP_ChangeLightColor(CurrentLightIndex);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ChangeLightColor(int Index) {}
}