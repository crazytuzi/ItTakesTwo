import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingForceImpactComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingImpactResponseComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingSoftImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Impact);

	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 135;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UHazeMovementComponent MoveComp;

	FIceSkatingAirSettings AirSettings;
	FIceSkatingImpactSettings ImpactSettings;
	FHitResult ImpactHit;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
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
		    float ImpactForce = LastVelocity.DotProduct(-Hit.Normal);
		    if (ImpactForce < ImpactSettings.SoftThreshold)
		        return EHazeNetworkActivation::DontActivate;

	        return EHazeNetworkActivation::ActivateUsingCrumb;
	    }
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
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
		FVector Velocity = MoveComp.PreviousVelocity;
		ImpactHit = MoveComp.ForwardHit;

		if (!HasControl())
		{
			Velocity = Params.GetVector(n"Velocity");
			ImpactHit.Normal = ImpactHit.ImpactNormal = Params.GetVector(n"HitNormal");
			ImpactHit.Location = ImpactHit.ImpactPoint = Params.GetVector(n"HitLocation");
			ImpactHit.Actor = Cast<AActor>(Params.GetObject(n"HitActor"));
			ImpactHit.Component = Cast<UPrimitiveComponent>(Params.GetObject(n"HitComponent"));
		}

		MoveComp.Velocity = Velocity.ConstrainToPlane(ImpactHit.Normal);
		MoveComp.Velocity += ImpactHit.Normal * ImpactSettings.SoftImpulse;

		SkateComp.CallOnSoftImpactEvent(ImpactHit.Location);
		Player.PlayForceFeedback(SkateComp.SoftImpactEffect, false, true, n"IceSkatingSoftImpact");

		// Animation bruh
		MoveComp.SetAnimationToBeRequested(n"SkateSoftImpact");

		// Check if its a right/left sided impact
		float SideDot = MoveComp.Velocity.CrossProduct(MoveComp.WorldUp).DotProduct(ImpactHit.Normal);
		if (SideDot < 0.f)
		{
			MoveComp.SetSubAnimationTagToBeRequested(n"RightImpact");
		}

		// Notify impact response components if there are any
		if (ImpactHit.Actor != nullptr)
		{
			auto ResponseComp = UIceSkatingImpactResponseComponent::Get(ImpactHit.Actor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnSoftImpact.Broadcast(Player, ImpactHit, MoveComp.PreviousVelocity);
			}
		}

		SkateComp.NextImpactTime = Time::GameTimeSeconds + ImpactSettings.Cooldown;

		if (SkateComp.bInstantImpactDeath && Player.CanPlayerBeKilled())
			Player.KillPlayer();
	}
}