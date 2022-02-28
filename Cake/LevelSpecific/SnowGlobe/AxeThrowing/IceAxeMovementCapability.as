import Cake.LevelSpecific.SnowGlobe.AxeThrowing.IceAxeActor;
import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;

class UIceAxeMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"IceAxeMovementCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AIceAxeActor IceAxe;
	AAxeThrowingTarget FollowingTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		IceAxe = Cast<AIceAxeActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IceAxe.bIsMoving)
        	return EHazeNetworkActivation::DontActivate;

		if (IceAxe.IceAxeState == EIceAxeState::Initiating)
        	return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IceAxe.bIsMoving)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (IceAxe.IceAxeState == EIceAxeState::Initiating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeTraceParams Trace;
		Trace.From = IceAxe.ActorLocation;
		Trace.SetToWithDelta(IceAxe.Velocity * DeltaTime);
		Trace.SetToSphere(5.f);
		Trace.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		Trace.IgnoreActor(Game::Cody);
		Trace.IgnoreActor(Game::May);

		FHazeHitResult Hit;
		Trace.Trace(Hit);

		if (Hit.bBlockingHit)
		{
			// Transform into relative, so that we're attached to the same point on both sides
			AIceAxeActor CheckIcicle  = Cast<AIceAxeActor>(Hit.Actor);

			if (CheckIcicle != nullptr)
				return;

			if (Hit.Actor == Game::May || Hit.Actor == Game::Cody)
				return;


			FTransform HitTransform = IceAxe.ActorTransform;
			FTransform CompTransform = Hit.Component.WorldTransform;
			HitTransform = HitTransform.GetRelativeTransform(CompTransform);

			if (IceAxe.PlayerOwner.HasControl())
				IceAxe.NetHandleControlHit(Hit.FHitResult, HitTransform, IceAxe.bIsDoublePoints);
			else
				IceAxe.HandleHit(Hit.FHitResult, HitTransform);
		}
		else
		{
			IceAxe.Velocity -= FVector::UpVector * IceAxe.Gravity * DeltaTime;
			Owner.AddActorWorldOffset(IceAxe.Velocity * DeltaTime);
			
			if (!IceAxe.Velocity.IsNearlyZero())
				Owner.SetActorRotation(Math::MakeRotFromX(IceAxe.Velocity));
		}
	}
}