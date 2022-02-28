import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkSpringBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BoardMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BoardMeshRoot)
	UStaticMeshComponent BoardMesh;

	UPROPERTY(DefaultComponent, Attach = BoardMesh)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirectionComp;

	FRotator StartingRotation;
	FRotator TargetRotation;

	float LaunchForce;

	bool bHasCheckedForLaunch = false;

	UPROPERTY()
	FHazeTimeLike SpringBoardTimeline;
	default SpringBoardTimeline.bLoop = true;
	default SpringBoardTimeline.Duration = 3.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpringBoardTimeline.BindUpdate(this, n"SpringBoardTimelineUpdate");
		StartingRotation = BoardMeshRoot.RelativeRotation;
		TargetRotation = FRotator(BoardMeshRoot.RelativeRotation.Pitch + 30.f, BoardMeshRoot.RelativeRotation.Yaw, BoardMeshRoot.RelativeRotation.Roll);
		SpringBoardTimeline.PlayFromStart();
	}

	UFUNCTION()
	void SpringBoardTimelineUpdate(float CurrentValue)
	{
		BoardMeshRoot.SetRelativeRotation(QuatLerp(StartingRotation, TargetRotation, CurrentValue));

		if (CurrentValue >= 0.8f)
		{
			LaunchPlayers();
		} else if (CurrentValue == 0.f)
		{
			ResetLaunch();
		}
	}

	void LaunchPlayers()
	{
		if (!bHasCheckedForLaunch)
		{
			bHasCheckedForLaunch = true;

			TArray<AActor> ActorArray;
			SphereCollision.GetOverlappingActors(ActorArray);

			LaunchForce = FMath::GetMappedRangeValueClamped(FVector2D(0.25f, 2.f), FVector2D(0.f, 4000.f), GetActorTimeDilation());

			for (AActor Actor : ActorArray)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
				if (Player != nullptr)
				{
					UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
					if (MoveComp.IsGrounded())
					{
						Player.AddImpulse(LaunchDirectionComp.GetForwardVector() * LaunchForce);
					}
				}
			}
		}
	}

	void ResetLaunch()
	{
		if (bHasCheckedForLaunch)
			bHasCheckedForLaunch = false;
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}