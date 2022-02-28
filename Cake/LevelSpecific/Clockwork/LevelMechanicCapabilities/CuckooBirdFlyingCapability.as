// import Cake.LevelSpecific.Clockwork.Actors.CuckooBird;

// class UCuckooBirdFlyingCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"CuckooBird");
	
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 100;

// 	AHazePlayerCharacter Player;
// 	ACuckooBird Bird;
// 	FVector CurrentInput = FVector::ZeroVector;
// 	FVector LerpedInput = FVector::ZeroVector;
// 	float FlapCooldownTimer = 0.f;
// 	float FlapCooldown = 1.65f;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Player.BlockCapabilities(CapabilityTags::Movement, this);
// 		Player.BlockCapabilities(CapabilityTags::Interaction, this);
// 		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
// 		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
// 		Player.BlockCapabilities(CapabilityTags::Input, this);
// 		Player.TriggerMovementTransition(this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Player.UnblockCapabilities(CapabilityTags::Movement, this);
// 		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
// 		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
// 		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
// 		Player.UnblockCapabilities(CapabilityTags::Input, this);
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		UObject BirdObject;
// 		if (ConsumeAttribute(n"CuckooBird", BirdObject))
// 		{
// 			Bird = Cast<ACuckooBird>(BirdObject);
// 		}
//     }

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		//FVector LeftStickVector = Bird.GetPlayerRawInput();
// 		LerpedInput = FMath::VInterpTo(LerpedInput, LeftStickVector, DeltaTime, 1.f);
// 		if (Bird != nullptr)
// 		{
// 			Bird.Input = LerpedInput;
// 		}

// 		FlapCooldownTimer -= DeltaTime;

// 		if(WasActionStarted(ActionNames::MovementJump) && Bird != nullptr && FlapCooldownTimer < 0)
// 		{
// 			Bird.FlapWings();
// 			FlapCooldownTimer = FlapCooldown;
// 		}
// 	}
// }