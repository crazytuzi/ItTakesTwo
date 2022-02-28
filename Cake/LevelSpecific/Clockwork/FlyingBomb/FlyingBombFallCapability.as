import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Trajectory.TrajectoryDrawer;

class UFlyingBombFallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombFall");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 105;

	AFlyingBomb Bomb;
	UHazeMovementComponent MoveComp;

	FQuat OriginalRotation;
	FQuat TargetRotation;

	FVector LaunchDirection;
	FVector LaunchTargetPoint;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
		MoveComp = Bomb.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"Dropped"))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Bomb.CurrentState != EFlyingBombState::Falling)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddVector(n"LaunchDirection", GetAttributeVector(n"LaunchDirection"));
		ActivationParams.AddVector(n"LaunchTargetPoint", GetAttributeVector(n"LaunchTargetPoint"));
		ActivationParams.EnableTransformSynchronizationWithTime(0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LaunchDirection = ActivationParams.GetVector(n"LaunchDirection");
		LaunchTargetPoint = ActivationParams.GetVector(n"LaunchTargetPoint");

		if (LaunchTargetPoint.IsNearlyZero())
		{
			MoveComp.SetVelocity(LaunchDirection * 20000.f);
		}
		else
		{
			FOutCalculateVelocity Path;
			Path = CalculateParamsForPathWithHeight(Bomb.ActorLocation, LaunchTargetPoint, Bomb.BombFallGravity, 0.f);
			MoveComp.SetVelocity(Path.Velocity);
		}

		OriginalRotation = Bomb.VisualRoot.ComponentQuat;

		FRotator TargRotator = FRotator::MakeFromX(LaunchDirection);
		TargRotator.Pitch += 90.f;

		TargetRotation = TargRotator.Quaternion();

		//OriginalRotation = TargetRotation;

		Bomb.State = EFlyingBombState::Falling;
		Bomb.BlockCapabilities(n"FlyingBombAI", this);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bomb.UnblockCapabilities(n"FlyingBombAI", this);
		ConsumeAction(n"Dropped");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	void ExplodeFromHit(AActor InHitActor)
	{
		Owner.SetCapabilityActionState(n"Explode", EHazeActionState::Active);

		auto HitActor = InHitActor;
		auto HitPlayer = Cast<AHazePlayerCharacter>(HitActor);
		auto HitBird = Cast<AClockworkBird>(HitActor);
		if (HitBird != nullptr)
			HitActor = HitBird.ActivePlayer;

		Owner.SetCapabilityAttributeObject(n"HitObject", HitActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.CanCalculateMovement())
		{
			FRotator NewRotation = FQuat::Slerp(
				OriginalRotation,
				TargetRotation,
				FMath::Clamp(ActiveDuration / 0.2f, 0.f, 1.f)
			).Rotator();

			//NewRotation = OriginalRotation.Rotator();

			FRotator NewVisualRotation;
			NewVisualRotation.Pitch = NewRotation.Pitch;
			NewVisualRotation.Roll = NewRotation.Roll;
			Bomb.VisualRoot.RelativeRotation = NewVisualRotation;

			FRotator NewActorRotation;
			NewActorRotation.Yaw = NewRotation.Yaw;

			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FlyingBombFall");
			FrameMove.SetRotation(NewActorRotation.Quaternion());
			FrameMove.ApplyActorHorizontalVelocity();
			FrameMove.ApplyActorVerticalVelocity();
			FrameMove.ApplyAcceleration(FVector(0.f, 0.f, -Bomb.BombFallGravity));
			FrameMove.OverrideCollisionProfile(n"PlayerCharacter");
			MoveComp.Move(FrameMove);

			//System::DrawDebugPoint(Owner.ActorLocation, 5.f, FLinearColor::White, 30.f);

			if (ActiveDuration > 5.f)
			{
				ExplodeFromHit(nullptr);
			}
			else if (MoveComp.ForwardHit.bBlockingHit)
			{
				ExplodeFromHit(MoveComp.ForwardHit.Actor);
			}
			else if (MoveComp.DownHit.bBlockingHit)
			{
				ExplodeFromHit(MoveComp.DownHit.Actor);
			}
		}
	}
};