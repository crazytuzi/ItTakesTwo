// 
// import Vino.Movement.MovementSystemTags;
// import Vino.Movement.Perch.PerchParams;
// import Vino.Movement.Perch.PerchTypes.BouncePerchComponent;
// import Vino.Time.ActorTimeDilationStatics;

// class UBouncePerchCapability : UHazeCapability
// {	
// 	default CapabilityTags.Add(PerchTags::Perch);

// 	default TickGroup = ECapabilityTickGroups::LastMovement;
// 	default TickGroupOrder = 140;

// 	default CapabilityDebugCategory = CapabilityTags::Movement;

//  	AHazePlayerCharacter PlayerOwner;
// 	UHazePlayerPointActivationComponent GrabPerchComponent;
// 	UHazeBaseMovementComponent MovementComponent;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
// 		GrabPerchComponent = UHazePlayerPointActivationComponent::Get(PlayerOwner);
// 		MovementComponent = UHazeBaseMovementComponent::Get(PlayerOwner);
// 	}

//     UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		auto ActivePerch = Cast<UBouncePerchComponent>(GrabPerchComponent.GetCurrentPerch());
// 		if (ActivePerch == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(GrabPerchComponent.GetPerchTravelType() != EHazeTotemTravelType::Done)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(GrabPerchComponent.CurrentActivationInstigatorIs())
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		return EHazeNetworkDeactivation::DeactivateLocal;
// 	}
	 
// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{	
// 		GrabPerchComponent.GrabCurrentPerch(this);
		
// 		FVector Impulse = MovementComponent.GetWorldUp() * 2000.f;
// 		Impulse += PlayerOwner.GetActorForwardVector() * 500.f;
// 		MovementComponent.AddImpulse(Impulse);
// 		PlayerOwner.SetCapabilityActionState(n"ResetAirDash", EHazeActionState::Active);
// 		PlayerOwner.SetCapabilityActionState(PerchTags::ForcePerchSearch, EHazeActionState::Active);
				
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		GrabPerchComponent.ReleaseCurrentPerch(this);
// 		PlayerOwner.SetCapabilityActionState(PerchTags::PerchTimeDilation, EHazeActionState::Active);
// 	}
// };
