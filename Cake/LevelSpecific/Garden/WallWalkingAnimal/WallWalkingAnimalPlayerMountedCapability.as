import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;

class UWallWalkingAnimalPlayerMountedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UWallWalkingAnimalComponent AnimalComp;

	UHazeMovementComponent MoveComp;
	UVineComponent VineComp;
	UWaterHoseComponent WaterComp;
	UPostProcessingComponent PostProcess;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimalComp = UWallWalkingAnimalComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		VineComp = UVineComponent::Get(Player);
		WaterComp = UWaterHoseComponent::Get(Player);
		PostProcess = UPostProcessingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AnimalComp.CurrentAnimal == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"ForceQuitRiding"))
		 	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAction(n"ForceQuitRiding");	
		Player.AddLocomotionFeature(AnimalComp.MovementFeature);
		PostProcess.SetPlayerFoliagePushSize(500.f);
		
		if(AnimalComp.AimCamSettings != nullptr)
		{
			if(WaterComp != nullptr)
				WaterComp.SetCustomAimCameraSettings(AnimalComp.AimCamSettings);
			if(VineComp != nullptr)
				VineComp.SetCustomAimCameraSettings(AnimalComp.AimCamSettings);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(n"ForceQuitRiding");
		Player.RemoveLocomotionFeature(AnimalComp.MovementFeature);
		PostProcess.SetPlayerFoliagePushSize(150.f);

		if(AnimalComp.AimCamSettings != nullptr)
		{
			if(WaterComp != nullptr)
				WaterComp.SetCustomAimCameraSettings(nullptr);
			if(VineComp != nullptr)
				VineComp.SetCustomAimCameraSettings(nullptr);
		}

		AnimalComp.CurrentAnimal.AnimalDismounted();
		AnimalComp.CurrentAnimal = nullptr;

		Player.MovementComponent.SetVelocity(FVector::ZeroVector);
	
		if (WasActionStarted(ActionNames::Cancel) && DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{
			Player.SetCapabilityActionState(n"ForceJump", EHazeActionState::Active);
		}
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if(VineComp != nullptr)
		{
			AnimalComp.CurrentAnimal.bRidingPlayerIsAiming = VineComp.bAiming;
		}
		else if(WaterComp != nullptr)
		{
			AnimalComp.CurrentAnimal.bRidingPlayerIsAiming = WaterComp.bWaterHoseActive;
		}

		// Apply the turning direction
		if(HasControl())
		{
			auto AnimalMoveComp = UHazeBaseMovementComponent::Get(AnimalComp.CurrentAnimal);
			if(AnimalMoveComp.IsGrounded())
			{
				FVector MovementRaw = GetAttributeVector(AttributeVectorNames::RightStickRaw);
				AnimalComp.CurrentAnimal.TuringDirection = MovementRaw.X;
				AnimalComp.CurrentAnimal.CrumbComp.SetCustomCrumbVector(FVector(AnimalComp.CurrentAnimal.TuringDirection * 100, 0, 0));
			}
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedParams;
			AnimalComp.CurrentAnimal.CrumbComp.GetCurrentReplicatedData(ReplicatedParams);
			AnimalComp.CurrentAnimal.TuringDirection = ReplicatedParams.CustomCrumbVector.X * 0.01f;
		}
				
		if(Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"GardenSpider";
			Player.RequestLocomotion(Request);
			Player.MovementComponent.SetVelocity(AnimalComp.CurrentAnimal.ActorVelocity);
		}
	}
}