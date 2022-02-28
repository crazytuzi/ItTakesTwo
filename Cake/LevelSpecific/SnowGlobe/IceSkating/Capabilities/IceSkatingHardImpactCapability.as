import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingForceImpactComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingImpactResponseComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Camera.Capabilities.CameraTags;

class UIceSkatingHardImpactCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Impact);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 130;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingAirSettings AirSettings;
	FIceSkatingImpactSettings ImpactSettings;
	FHitResult ImpactHit;

	float Timer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
	}

	FVector CalculateEffectiveNormal(FVector Normal) const
	{
		if (MoveComp.IsAirborne())
		{
			return Normal;
		}
		else
		{
			// If we're grounded we dont want to reflect upwards at all, so flatten the normal to the ground
			FVector FlatNormal = Math::ConstrainVectorToSlope(Normal, MoveComp.DownHit.Normal, MoveComp.WorldUp);
			return FlatNormal.GetSafeNormal();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

	    if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

	    FHitResult Hit = MoveComp.ForwardHit;
	    if (!Hit.bBlockingHit)
	        return EHazeNetworkActivation::DontActivate;

	    if (Time::GameTimeSeconds < SkateComp.NextImpactTime)
	        return EHazeNetworkActivation::DontActivate;

	    // Some actors are marked to force an impact when running into them (like villagers)
	    auto ForceImpactComp = UIceSkatingForceImpactComponent::Get(Hit.Actor);
	    if (ForceImpactComp != nullptr && ForceImpactComp.bIsHardImpact)
	    {
	        return EHazeNetworkActivation::ActivateUsingCrumb;
	    }

	    // Otherwise see if we're going fast enough into it
	    else
	    {
		    FVector LastVelocity = MoveComp.PreviousVelocity;
		    FVector Normal = CalculateEffectiveNormal(Hit.Normal);
		    float ImpactForce = LastVelocity.DotProduct(-Normal);
		    if (ImpactForce < ImpactSettings.HardThreshold)
		        return EHazeNetworkActivation::DontActivate;

	        return EHazeNetworkActivation::ActivateUsingCrumb;
	    }
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
	    if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Timer >= ImpactSettings.HardDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.BecameGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddVector(n"Velocity", MoveComp.PreviousVelocity);
		Params.AddVector(n"HitNormal", MoveComp.ForwardHit.Normal);
		Params.AddVector(n"HitLocation", MoveComp.ForwardHit.Location);
		Params.AddObject(n"HitActor", MoveComp.ForwardHit.Actor);
		Params.AddObject(n"HitComponent", MoveComp.ForwardHit.Component);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Timer = 0.f;
		ImpactHit = MoveComp.ForwardHit;
		FVector Velocity = MoveComp.PreviousVelocity;

		if (!HasControl())
		{
			Velocity = Params.GetVector(n"Velocity");
			ImpactHit.Normal = ImpactHit.ImpactNormal = Params.GetVector(n"HitNormal");
			ImpactHit.Location = ImpactHit.ImpactPoint = Params.GetVector(n"HitLocation");
			ImpactHit.Actor = Cast<AActor>(Params.GetObject(n"HitActor"));
			ImpactHit.Component = Cast<UPrimitiveComponent>(Params.GetObject(n"HitComponent"));
		}

		FVector Normal = CalculateEffectiveNormal(ImpactHit.Normal);
		FVector Impulse = FMath::GetReflectionVector(Velocity, Normal);
		MoveComp.Velocity = Impulse * ImpactSettings.HardSpeedLoss;
		MoveComp.Velocity += MoveComp.WorldUp * ImpactSettings.HardUpImpulse;

		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		SetMutuallyExclusive(IceSkatingTags::Impact, true);

		SkateComp.CallOnHardImpactEvent(ImpactHit.Location);
		Player.PlayForceFeedback(SkateComp.HardImpactEffect, false, true, n"IceSkatingHardImpact");

		// Notify impact response components if there are any
		if (ImpactHit.Actor != nullptr)
		{
			auto ResponseComp = UIceSkatingImpactResponseComponent::Get(ImpactHit.Actor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnHardImpact.Broadcast(Player, ImpactHit, Velocity);
			}
		}

		SkateComp.NextImpactTime = Time::GameTimeSeconds + ImpactSettings.Cooldown;

		if (SkateComp.bInstantImpactDeath && Player.CanPlayerBeKilled())
			Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		SetMutuallyExclusive(IceSkatingTags::Impact, false);

		if (MoveComp.BecameGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"SkateImpactHard");
		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);

		if (HasControl())
		{
			Timer += DeltaTime;

			FVector Velocity = MoveComp.Velocity;
			Velocity -= Velocity * ImpactSettings.HardImpulseDrag * DeltaTime;

			if (MoveComp.IsAirborne())
			{
				Velocity -= MoveComp.WorldUp * AirSettings.Gravity * DeltaTime; 
			}

			FrameMove.ApplyVelocity(Velocity);

			MoveCharacter(FrameMove, n"SkateHardImpact");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"SkateHardImpact");
		}
	}
}
