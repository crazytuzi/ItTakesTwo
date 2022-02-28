import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class UWindWalkCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"WindWalk");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"WindWalk";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UWindWalkComponent WindWalkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WindWalkComp = UWindWalkComponent::GetOrCreate(Player);
		WindWalkComp.PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WindWalkComp.CurrentForce.Size() < 200.f)
			return EHazeNetworkActivation::DontActivate;

//		if (WindWalkComp.GetWindForce().Size() < 50.f)
//			return EHazeNetworkActivation::DontActivate;

//		if (WindWalkComp.ActiveVolumes.Num() <= 0)
//			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WindWalkComp.CurrentForce.Size() < 50.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

//		if (WindWalkComp.GetWindForce().Size() < 50.f)
//			return EHazeNetworkDeactivation::DeactivateLocal;

//		if (WindWalkComp.ActiveVolumes.Num() <= 0)
//			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		WindWalkComp.bIsWindWalking = true;

		WindWalkComp.PlayerWindEffectComponent.Activate();

		Player.AddLocomotionAsset(GetLocomotionAsset(), this);

		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::Crouch, this);
		Player.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		WindWalkComp.bIsWindWalking = false;

//		WindWalkComp.CurrentForce = FVector::ZeroVector;

		WindWalkComp.PlayerWindEffectComponent.Deactivate();

		Player.ClearLocomotionAssetByInstigator(this);

		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::Crouch, this);
		Player.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Print("WindWalk");
	//	Print("GetVelocity: " + MoveComp.GetVelocity().Size());
		// Print("Force: " + WindWalkComp.CurrentForce.Size());
	}

	UHazeLocomotionStateMachineAsset GetLocomotionAsset()
	{
		// Use standard locomotion asset if player attraction is not active
		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComp = UMagneticPlayerAttractionComponent::Get(Player);
		if(MagneticPlayerAttractionComp == nullptr || !MagneticPlayerAttractionComp.IsPlayerAttractionActive())
			return Player.IsMay() ? WindWalkComp.LocomotionAssetMay : WindWalkComp.LocomotionAssetCody;

		// Choose different asset depending on player magnetic attraction state
		return MagneticPlayerAttractionComp.bIsPiggybacking ?
			MagneticPlayerAttractionComp.PlayerAttractionPerchAnimationDataAsset.CarryStateMachine :
			MagneticPlayerAttractionComp.PlayerAttractionPerchAnimationDataAsset.PiggybackStateMachine;
	}
}