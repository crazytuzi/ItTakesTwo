import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

event void FChangeDirection();

class ACurlingObstacle : AHazeActor
{
	FChangeDirection EventChangeDirection;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = MovementRoot, ShowOnActor)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UBoxComponent BoxCollision;
	default BoxCollision.AddTag(n"IceSkateable");

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ObstacleMove;

	FHazeConstrainedPhysicsValue Position;
	default Position.UpperBound = 220.f;
	default Position.LowerBound = 0.f;
	default Position.Friction = 1.2f;
	default Position.UpperBounciness = 0.4;
	default Position.LowerBounciness = 0.4;

	bool bObstacleActive = false;
	bool bIsSleeping = true;
	float AccelScale = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccelScale = FMath::RandRange(0.8f, 1.2f);
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void ActivateObstacle()
	{
		bObstacleActive = true;
		WakeUp();
	}

	UFUNCTION()
	void DeactivateObstacle()
	{
		bObstacleActive = false;
		WakeUp();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float PrevVelocity = Position.Velocity;
		float PrevValue = Position.Value;

		Position.AccelerateTowards(bObstacleActive ? 220.f : 0.f, 1400.f * AccelScale);
		Position.Update(DeltaTime);

		if (FMath::IsNearlyEqual(PrevVelocity, Position.Velocity) &&
			FMath::IsNearlyEqual(PrevValue, Position.Value))
			Sleep();

		MovementRoot.RelativeLocation = FVector(0.f, 0.f, Position.Value);
	}

	void WakeUp()
	{
		if (!bIsSleeping)
			return;

		if (IsActorDisabled())
			return;

		bIsSleeping = false;
		SetActorTickEnabled(true);
	}

	void Sleep()
	{
		if (bIsSleeping)
			return;

		bIsSleeping = true;
		SetActorTickEnabled(false);
	}
}