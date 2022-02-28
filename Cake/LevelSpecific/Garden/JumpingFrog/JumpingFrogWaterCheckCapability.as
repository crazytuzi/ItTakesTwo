// import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
// import Vino.Movement.Components.MovementComponent;

// class UJumpingFrogWaterCheckCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
// 	default CapabilityTags.Add(CapabilityTags::Movement);

// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
// 	default TickGroupOrder = 40;

// 	AJumpingFrog OwningFrog;
// 	UHazeMovementComponent MoveComp;

// 	bool bGroundedCooldown = false;

// 	float GroundedCooldownTimer = 0.0f;
// 	float GroundedCooldownDuration = 0.5f;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		OwningFrog = Cast<AJumpingFrog>(Owner);
// 		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (!HasControl())
//         	return EHazeNetworkActivation::DontActivate;
		
// 		if (!HitWater())
//         	return EHazeNetworkActivation::DontActivate;

//         return EHazeNetworkActivation::ActivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(bGroundedCooldown)
// 			return EHazeNetworkDeactivation::DontDeactivate;

// 		if (!MoveComp.IsGrounded() && !HitWater())
// 			return EHazeNetworkDeactivation::DontDeactivate;
		
// 		return EHazeNetworkDeactivation::DeactivateLocal;
// 	}

// 	bool HitWater() const
// 	{
// 		if(MoveComp.DownHit.Actor != nullptr)
// 		{
// 			if(MoveComp.DownHit.Actor.ActorHasTag(n"Water"))
// 			{
// 				return true;
// 			}
// 			else if(MoveComp.DownHit.Component != nullptr)
// 			{
// 				if(MoveComp.DownHit.Component.HasTag(n"Water"))
// 				 {
// 					 return true;
// 				 }
// 			}
// 		}
		
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Owner.SetCapabilityActionState(JumpingFrogTags::Death, EHazeActionState::Active);
// 	}
// }