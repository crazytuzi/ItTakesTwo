import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Vino.Movement.Components.MovementComponent;

class APowerfulSongPushableActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PushableMesh;

	UPROPERTY(DefaultComponent)
	UDEPRECATED_PowerfulSongImpactComponent PowerfulSongImpactComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritVelocityComp;
	
	FVector CurrentSongDirection;

	bool bAffectedBySong = false;

	FVector CurVelocity = FVector::ZeroVector;
	FVector CurDirection = FVector::ZeroVector;

	float CurSpeed = 0.f;
	float MaxSpeed = 110000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CollisionComp);

		PowerfulSongImpactComp.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION()
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		CurDirection = Math::ConstrainVectorToPlane(Info.Direction, FVector::UpVector);
		CurSpeed = MaxSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurSpeed -= 50000.f * DeltaTime;
		CurSpeed = FMath::Clamp(CurSpeed, 0.f, MaxSpeed);
		CurVelocity = CurDirection * CurSpeed * DeltaTime;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PowerfulSongPushableActor");
		MoveData.ApplyVelocity(CurVelocity);
		// MoveData.ApplyActorVerticalVelocity();
		// MoveData.ApplyGravityAcceleration();
		MoveData.OverrideStepUpHeight(0.f);
		MoveComp.Move(MoveData);
	}
}