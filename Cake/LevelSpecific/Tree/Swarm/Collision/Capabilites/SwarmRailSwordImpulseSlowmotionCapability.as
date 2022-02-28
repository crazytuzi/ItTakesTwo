
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageResponseCapability;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindSpline;
import Vino.PlayerHealth.PlayerHealthComponent;

class USwarmRailSwordImpulsePlayerResponseComponent : UActorComponent 
{
	bool bGrappleTargeted = false;
	bool bGrappleAttached = false;
	float TimeStampActivated = 0.f;
	float TimeStampGrappleAttached = 0.f;

	bool CanDamagePlayer() const
	{
		const float GrappleInvulnerabilityTimer = Time::GetGameTimeSince(TimeStampGrappleAttached);
		// PrintToScreen(Owner.GetName() + " GrappleInvulnerabilityTimer: " + GrappleInvulnerabilityTimer);
		if (GrappleInvulnerabilityTimer < 2.0f)
			return false;

		UUserGrindComponent GrindComp = UUserGrindComponent::Get(Owner);
		if (!GrindComp.HasActiveGrindSpline())
			return false;

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Owner); 
		if (!HealthComp.CanTakeDamage())
			return false;

		return true;
	}
}

class USwarmRailSwordImpulseSlowmotionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UPROPERTY(Category = "Oh yeah!?")
	UHazeCameraSettingsDataAsset OnflingedCamSettings;

	UPROPERTY(Category = "Oh yeah!?")
	UMovementSettings SkyDiveMovementSettings;

	UPROPERTY()
	UAnimSequence CodyKnockedOffAnim;

	UPROPERTY()
	UAnimSequence MayKnockedOffAnim;

	FHazeAnimationDelegate OnKnockOffFinished;
	bool bIsSkydive = false;

	AHazePlayerCharacter Player;
	UUserGrindComponent GrindComp;

	// so that the swarm can read info
	USwarmRailSwordImpulsePlayerResponseComponent ResponseComp;

	FVector DesiredLookatPosition;

	float TimeSinceActivated = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrindComp = UUserGrindComponent::Get(Player);
		ResponseComp = USwarmRailSwordImpulsePlayerResponseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"SwarmRailImpulse"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// I'm thinking that local deactivation will look nicer
		// but I'm not quite sure if mixing Local and crumbs is OK
		if(ResponseComp.bGrappleAttached)
			return EHazeNetworkDeactivation::DeactivateLocal;	

		if(Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// UFUNCTION(BlueprintOverride)
	// void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	// {
	// 	OutParams.AddObject(n"Spline", GrindComp.GetActiveGrindSpline().);
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(ActionNames::WeaponAim, this);

		if(GrindComp == nullptr)
		{
#if TEST
			// does this happen when player dies!?
			devEnsure(false, 
				"The grind component has been nullified on " + 
				Player + 
				". Did this happen after the player died? \n Please let Sydney know about this");
#endif
			GrindComp = UUserGrindComponent::Get(Player);
		}

		TimeSinceActivated = 0.f;
		bIsSkydive = false;

		// const float CanBeHitCooldownTimer = Time::GetGameTimeSince(ResponseComp.TimeStampGrappleAttached);
		// Print("RailSwordImpulse! CooldownTimer: " + CanBeHitCooldownTimer, 5.f, FLinearColor::Red);

		ResponseComp.TimeStampActivated = Time::GetGameTimeSeconds();

		Player.ApplySettings(SkyDiveMovementSettings, this, EHazeSettingsPriority::Script);

		// get the spline. "Active" when we are grinding. "Previous" when we are jumping.
		UHazeSplineComponent SplineToQuery = nullptr;
		if(GrindComp.ActiveGrindSpline != nullptr)
			SplineToQuery = GrindComp.ActiveGrindSpline.Spline;
		else if(GrindComp.PreviousActiveGrindSpline != nullptr)
			SplineToQuery = GrindComp.PreviousActiveGrindSpline.Spline;
		else
		{
#if TEST
			devEnsure(false, 
				"The grind component has no valid spline data on it... nothing to query on " + 
				Player + 
				". Did this happen after the player died? \n Please let Sydney know about this");
#endif
		}

		// Find Desired look at pos
		DesiredLookatPosition = SplineToQuery.GetPositionClosestToWorldLocation(
			Player.ActorLocation + Player.ActorForwardVector * 1500.f
		).WorldLocation;

		// Detach from grind spline
		// (this might be a problematic in network unless we activate using crumbs..)
		Player.BlockCapabilities(MovementSystemTags::Grinding, this);

		FVector Impulse = FVector::UpVector * 3000.f;
		FVector PlayerVelocity = Player.MovementComponent.Velocity;
		PlayerVelocity = PlayerVelocity.VectorPlaneProject(FVector::UpVector);
		PlayerVelocity.Normalize();
		PlayerVelocity *= 2000.f;
		Impulse += PlayerVelocity;
		
		// Knockdown will zero out player velocity and apply this impulse

		//Owner.SetCapabilityAttributeVector(n"KnockdownDirection", Impulse);
		//Owner.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

		Player.MovementComponent.Velocity = FVector::ZeroVector;
		Player.MovementComponent.AddImpulse(Impulse);
		
		
		OnKnockOffFinished.BindUFunction(this, n"OnKnockOffDone");

		if (Player.IsCody())
		{
			Owner.PlaySlotAnimation(Animation = CodyKnockedOffAnim, OnBlendingOut =  OnKnockOffFinished);
		}
			
		else
		{
			Owner.PlaySlotAnimation(Animation = MayKnockedOffAnim, OnBlendingOut =  OnKnockOffFinished);
		}
		
		// allow grind again next tick
		Player.UnblockCapabilities(MovementSystemTags::Grinding, this);

		ResponseComp.bGrappleTargeted = false;
		ResponseComp.bGrappleAttached = false;
		GrindComp.OnGrindSplineTargeted.AddUFunction(this, n"GrappleTargeted");
		GrindComp.OnGrindSplineAttached.AddUFunction(this, n"GrappleAttached");

		// Apply unique camera settings
		FHazeCameraBlendSettings BlendSettings;
		Player.ApplyCameraSettings(OnflingedCamSettings, BlendSettings, this, EHazeCameraPriority::Script);
		Player.DamagePlayerHealth(0.333f);
	}

	UFUNCTION()
	void OnKnockOffDone()
	{
		if (IsActive())
		{
			bIsSkydive = true;
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		GrindComp.OnGrindSplineTargeted.Unbind(this, n"GrappleTargeted");
		GrindComp.OnGrindSplineAttached.Unbind(this, n"GrappleAttached");

		OnKnockOffFinished.Clear();
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearSettingsWithAsset(SkyDiveMovementSettings, this);
		Player.CustomTimeDilation = 1.f;

		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeSinceActivated += DeltaTime;

		// Delay custom time dilation for 0.5 seconds
		const float TimeSinceDilationStarted = TimeSinceActivated - 0.5f;
		if(TimeSinceDilationStarted >= 0.f)
		{
			const float Alpha = FMath::Min(TimeSinceDilationStarted, 1.f); 
			Player.CustomTimeDilation = FMath::Lerp(0.2f, 1.f, Alpha);
		}
		else
		{
			Player.CustomTimeDilation = 1.f;
		}

		// Partially disable the capability. We'll deactivate the capability 
		// entirely once the player is attached to the spline
		if(ResponseComp.bGrappleTargeted || TimeSinceActivated >= 1.5f)
		{
			Player.CustomTimeDilation = 1.f;
			Player.ClearCameraSettingsByInstigator(this);
			Player.ClearPointOfInterestByInstigator(this);
			Player.ClearSettingsWithAsset(SkyDiveMovementSettings, this);
			return;
		}

		// Update Point of interest
		FHazePointOfInterest POI;
		POI.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		POI.FocusTarget.WorldOffset = DesiredLookatPosition;
		Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::Script);

		if(bIsSkydive)
		{
			FHazeRequestLocomotionData LocoRequest;
			LocoRequest.AnimationTag = n"Skydive";
			Player.RequestLocomotion(LocoRequest);
		}
	}

	UFUNCTION()
	void GrappleTargeted(AGrindspline GrindSpline, EGrindTargetReason Reason)
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearSettingsWithAsset(SkyDiveMovementSettings, this);
		Player.CustomTimeDilation = 1.f;
		ResponseComp.bGrappleTargeted = true;
	}

	UFUNCTION()
	void GrappleAttached(AGrindspline GrindSpline, EGrindAttachReason Reason)
	{
		ResponseComp.TimeStampGrappleAttached = Time::GetGameTimeSeconds();
		ResponseComp.bGrappleAttached = true;
	}

}