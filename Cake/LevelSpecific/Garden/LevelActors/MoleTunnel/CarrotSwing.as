import Vino.Movement.Swinging.SwingComponent;
import Vino.Movement.Swinging.SwingPoint;

class ACarrotSwing: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshBody;
	UPROPERTY()
	ASwingPoint SwingPointActor;

	float SwingDurabilityTime = 4.5f;
	int AmountPlayersAttached = 0;
	const float MoveDistanceValue = 550;
	const float MaxDistanceBeforeFinalGroundPound = 410;
	const float MoveSpeed = 1.f / 4.f;
	float TargetMoveDistance = 0;
	float MoleMoveDistance = 0;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SwingPointActor.SwingPointComponent.OnSwingPointAttached.AddUFunction(this, n"SwingPointAttached");
		SwingPointActor.SwingPointComponent.OnSwingPointDetached.AddUFunction(this, n"SwingPointDetached");
		const float MaxMove = MaxDistanceBeforeFinalGroundPound - MoleMoveDistance;
		TargetMoveDistance += FMath::Min(MoveDistanceValue, MaxMove);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(AmountPlayersAttached >= 1)
		{
			const float NewMoveDistance = FMath::FInterpTo(MoleMoveDistance, TargetMoveDistance, DeltaTime, MoveSpeed);
			const float MinMoveAmount = 5.f * DeltaTime;
			
			// The closer we reach the target, the closer to no movement we get. This will prevent that
			float MoveAmount = NewMoveDistance - MoleMoveDistance;
			if(MoveAmount < MinMoveAmount)
				MoveAmount = FMath::Min(MinMoveAmount, TargetMoveDistance - MoleMoveDistance);

			MoleMoveDistance += MoveAmount;
			FVector FinalLocation = GetActorLocation();
			FinalLocation.Z -= MoveAmount;
			SetActorLocation(FinalLocation);
		}
	}

	UFUNCTION()
	void SwingPointAttached(AHazePlayerCharacter Player)
	{
		AmountPlayersAttached ++;
	}

	UFUNCTION()
	void SwingPointDetached(AHazePlayerCharacter Player)
	{
		AmountPlayersAttached --;
	}
}

