import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Vino.Movement.CollisionIgnoreStatics;

class AClockworkLauncherBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirection;
	default LaunchDirection.RelativeRotation = FRotator(90.f, 0.f, 0.f);
	default LaunchDirection.ArrowSize = 10.f;

	UPROPERTY(DefaultComponent)
	UTimeControlActorComponent TimeControl;
	// default TimeControl.bCanBeTimeControlled = true;
	// default TimeControl.bAddConstantProgression = true;
	// default TimeControl.ConstantIncreaseValue = 4.f;
	// default TimeControl.StartingPointInTime = 1.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY()
	float LaunchImpulse = 3500.f;

	private float ReachedPullBack = 1.f;

	bool bLaunched = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControl.TimeIsChangingEvent.AddUFunction(this, n"OnTimeChanged");
	}

	UFUNCTION()
	void LaunchPlayer(AHazePlayerCharacter Player, float ImpulseMultiplier = 1.f, bool bTemporarilyIgnoreCollision = false)
	{
		if (ImpulseMultiplier > 0.f)
		{
			Player.AddImpulse(LaunchDirection.ForwardVector * ImpulseMultiplier * LaunchImpulse);

			FVector ConstrainedDir = Math::ConstrainVectorToPlane(LaunchDirection.ForwardVector, FVector::UpVector);
			ConstrainedDir.Normalize();
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			if (MoveComp != nullptr)
				MoveComp.SetTargetFacingDirection(ConstrainedDir);

			FHazePointOfInterest PoI;
			PoI.Duration = 1.f;
			PoI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
			PoI.FocusTarget.WorldOffset = ActorLocation + (ConstrainedDir * 6500.f);
			PoI.Blend.BlendTime = 0.75f;
			Player.ApplyPointOfInterest(PoI, this);

			Player.PlayForceFeedback(LaunchForceFeedback, false, true, n"Launch");
			Player.PlayCameraShake(LaunchCameraShake, 0.35);
		}
		if (bTemporarilyIgnoreCollision)
			TemporarilyIgnoreActorCollision(Player, this, 0.5f);
	}

	UFUNCTION()
	void LaunchOverlappingPlayers(UPrimitiveComponent Collision, float ImpulseMultiplier = 1.f, bool bTemporarilyIgnoreCollision = false)
	{
		TArray<AActor> Actors;
		Collision.GetOverlappingActors(Actors);

		for (auto Actor : Actors)
		{
			auto Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player != nullptr)
				LaunchPlayer(Player, ImpulseMultiplier, bTemporarilyIgnoreCollision);
		}
	}

	UFUNCTION()
	float ConsumeSpring()
	{
		float SpringValue = (1.f - ReachedPullBack);
		ReachedPullBack = 1.f;
		return SpringValue;
	}

	UFUNCTION()
	void OnTimeChanged(float Time)
	{
		if (Time < ReachedPullBack)
			ReachedPullBack = Time;

		if (Time >= 0.42f && !bLaunched)
		{
			OnLaunch(ConsumeSpring());
			bLaunched = true;
		}

		if (Time <= 0.1f)
			bLaunched = false;
	}

	UFUNCTION(BlueprintEvent)
	void OnLaunch(float SpringStrength) {}
};