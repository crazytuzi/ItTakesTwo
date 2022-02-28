import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.SilentRoomMovingPlatformTargets;
import Vino.Bounce.BounceComponent;
class ASilentRoomMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BaseMeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformMeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UBounceComponent BounceComp;

	UPROPERTY()
	TArray<ASilentRoomMovingPlatformTarget> TargetLocArray;

	FVector StartingLoc;
	FVector TargetLoc = FVector(1000.f, 0.f, 0.f);

	FVector LocLastTick;

	UPROPERTY()
	int CurrentTargetIndex = 1;

	FVector LocationBeforeMove;
	FVector CurrentTarget;
	FVector LocationLerp;

	float MoveTimerMax = 1.5f;
	float MoveTimer = 0.f;
	bool bShouldTickMoveTimer = false;

	float CooldownTimerMax = 2.f;
	float CooldownTimer = 0.f;
	bool bShouldTickCooldown = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LocationLerp = ActorLocation;
		//MovePlatformToNextLocation();

	} 

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldTickMoveTimer)
		{
			MoveTimer += DeltaTime;
			LocationLerp = FMath::Lerp(LocationBeforeMove, CurrentTarget, MoveTimer/MoveTimerMax);
			if (MoveTimer >= MoveTimerMax)
			{
				MoveTimer = MoveTimerMax;
				bShouldTickMoveTimer = false;
				CooldownTimer = 0.f;
				//bShouldTickCooldown = true;
			}
		}

		if (bShouldTickCooldown)
		{
			CooldownTimer += DeltaTime;
			if (CooldownTimer >= CooldownTimerMax)
			{
				CooldownTimer = CooldownTimerMax;
				bShouldTickCooldown = false;
				MovePlatformToNextLocation();
			}
		}

		SetActorLocation(FMath::VInterpTo(ActorLocation, LocationLerp, DeltaTime, 2.f));

		FVector Dir = LocationLerp - LocLastTick;
		float MoveSpeed = Dir.Size();
		MoveSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 500.f), FVector2D(0.f, 10.f), MoveSpeed);
		Dir.GetSafeNormal();
		FVector Cross = GetActorUpVector().CrossProduct(Dir);
		FRotator Rot = FMath::RotatorFromAxisAndAngle(Cross, -MoveSpeed);
		SetActorRotation(Rot);
		LocLastTick = ActorLocation;		
	}

	UFUNCTION()
	void MovePlatformToNextLocation()
	{
		LocationBeforeMove = ActorLocation;
		MoveTimer = 0.f;
		CurrentTarget = GetNextLocation();
		bShouldTickMoveTimer = true;
	}

	FVector GetNextLocation()
	{
		FVector NewTargetLoc;
		for (auto Target : TargetLocArray)
		{
			if (CurrentTargetIndex == TargetLocArray.Num())
			{
				if (Target.MoveOrder == 1)
					NewTargetLoc = Target.ActorLocation;
			} else
			{
				if (Target.MoveOrder == CurrentTargetIndex + 1)
					NewTargetLoc = Target.ActorLocation;
			}
		}

		CurrentTargetIndex++;
		
		if (CurrentTargetIndex > TargetLocArray.Num())
			CurrentTargetIndex = 1;
		
		return NewTargetLoc;
	}

	UFUNCTION(CallInEditor)
	void GetAllTargets()
	{
		GetAllActorsOfClass(TargetLocArray);
	}
}